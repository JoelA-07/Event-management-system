const Booking = require('../models/Booking');
const VendorBooking = require('../models/VendorBooking');
const Hall = require('../models/Hall');
const VendorService = require('../models/VendorService');
const User = require('../models/User');
const Payment = require('../models/Payment');
const PaymentTransaction = require('../models/PaymentTransaction');
const Payout = require('../models/Payout');
const { getRazorpayClient, verifyWebhookSignature, verifyPaymentSignature } = require('../services/razorpayService');
const { notifyUser, notifyOrganizers } = require('../services/notificationService');
const { toNumber, computeStatus, recordRefund } = require('../services/paymentService');
const { getPagination, isPaginated, buildPageResponse } = require('../utils/pagination');
const { RAZORPAY_KEY_ID } = require('../config/env');
const PDFDocument = require('pdfkit');

async function ensureReceipt(payment) {
  if (payment.receiptNumber) return;
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  payment.receiptNumber = `REC-${date}-${payment.id}`;
  payment.receiptIssuedAt = new Date();
  await payment.save();
}

async function getOrCreatePayment({ bookingType, bookingId }) {
  let payment = await Payment.findOne({ where: { bookingType, bookingId } });
  if (payment) return payment;

  if (bookingType === 'hall') {
    const booking = await Booking.findByPk(bookingId);
    if (!booking) throw new Error('Hall booking not found');
    const hall = await Hall.findByPk(booking.hallId);
    if (!hall) throw new Error('Hall not found');

    payment = await Payment.create({
      bookingType,
      bookingId,
      customerId: booking.customerId,
      totalAmount: hall.pricePerDay,
      advanceAmount: 0,
    });
    return payment;
  }

  if (bookingType === 'vendor') {
    const booking = await VendorBooking.findByPk(bookingId);
    if (!booking) throw new Error('Vendor booking not found');
    const service = await VendorService.findByPk(booking.serviceId);
    if (!service) throw new Error('Vendor service not found');

    payment = await Payment.create({
      bookingType,
      bookingId,
      customerId: booking.customerId,
      vendorId: booking.vendorId,
      totalAmount: service.price,
      advanceAmount: 0,
    });
    return payment;
  }

  throw new Error('Invalid booking type');
}

function resolveAmountToCharge(payment, type) {
  const total = toNumber(payment.totalAmount);
  const advance = toNumber(payment.advanceAmount);
  const paid = toNumber(payment.paidAmount);
  const refunded = toNumber(payment.refundedAmount);
  const netPaid = Math.max(paid - refunded, 0);
  const remaining = Math.max(total - netPaid, 0);

  if (type === 'advance') {
    if (advance <= 0) throw new Error('Advance is not set');
    if (netPaid >= advance) throw new Error('Advance already paid');
    return Math.min(advance - netPaid, remaining);
  }
  if (type === 'balance') {
    if (remaining <= 0) throw new Error('Payment already completed');
    return remaining;
  }

  throw new Error('Invalid payment type');
}

async function finalizeSuccessfulTransaction(transaction, { razorpayPaymentId } = {}) {
  if (transaction.status === 'paid') {
    const payment = await Payment.findByPk(transaction.paymentId);
    return { payment, transaction };
  }

  transaction.status = 'paid';
  transaction.razorpayPaymentId = razorpayPaymentId || transaction.razorpayPaymentId;
  transaction.paidAt = new Date();
  await transaction.save();

  const payment = await Payment.findByPk(transaction.paymentId);
  if (payment) {
    const total = toNumber(payment.totalAmount);
    const paid = toNumber(payment.paidAmount) + toNumber(transaction.amount);
    payment.paidAmount = paid;
    payment.status = computeStatus(total, paid, payment.refundedAmount);
    await payment.save();

    if (payment.status === 'paid') {
      await ensureReceipt(payment);
    }

    try {
      await notifyUser(payment.customerId, 'paymentAlerts', {
        title: 'Payment received',
        body: `Online payment of Rs ${transaction.amount} received.`,
        data: { type: 'payment_online', paymentId: payment.id, amount: transaction.amount },
      });
      if (payment.vendorId) {
        await notifyUser(payment.vendorId, 'paymentAlerts', {
          title: 'Payment update',
          body: `Payment updated for booking ${payment.bookingId}.`,
          data: { type: 'payment_online', paymentId: payment.id, amount: transaction.amount },
        });
      }
      await notifyOrganizers({
        title: 'Payment completed',
        body: `Rs ${transaction.amount} received for booking ${payment.bookingId}.`,
        data: { type: 'payment_online', paymentId: payment.id, amount: transaction.amount },
      });
    } catch (_) {}
  }

  return { payment, transaction };
}

exports.getPaymentSummary = async (req, res) => {
  try {
    const { bookingType, bookingId } = req.params;
    const payment = await getOrCreatePayment({ bookingType, bookingId });

    if (req.user?.role !== 'organizer' && Number(req.user?.id) !== Number(payment.customerId) && Number(req.user?.id) !== Number(payment.vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const transactionsQuery = {
      where: { paymentId: payment.id },
      order: [['id', 'DESC']],
    };
    const payoutsQuery = {
      where: { paymentId: payment.id },
      order: [['id', 'DESC']],
    };

    let transactionsResult;
    let payoutsResult;

    if (isPaginated(req.query)) {
      const { page, limit, offset } = getPagination(req.query);
      transactionsResult = await PaymentTransaction.findAndCountAll({ ...transactionsQuery, limit, offset });
      payoutsResult = await Payout.findAndCountAll({ ...payoutsQuery, limit, offset });
      return res.json({
        payment,
        transactions: buildPageResponse({ rows: transactionsResult.rows, count: transactionsResult.count, page, limit }),
        payouts: buildPageResponse({ rows: payoutsResult.rows, count: payoutsResult.count, page, limit }),
      });
    }

    const transactions = await PaymentTransaction.findAll(transactionsQuery);
    const payouts = await Payout.findAll(payoutsQuery);

    return res.json({ payment, transactions, payouts });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to load payment summary', error: error.message });
  }
};

exports.setPaymentPlan = async (req, res) => {
  try {
    const { paymentId } = req.params;
    const { advanceAmount, organizerFeePercent } = req.body;

    const payment = await Payment.findByPk(paymentId);
    if (!payment) return res.status(404).json({ message: 'Payment not found' });

    const total = toNumber(payment.totalAmount);
    const advance = advanceAmount != null ? toNumber(advanceAmount) : toNumber(payment.advanceAmount);

    if (advance < 0 || advance > total) {
      return res.status(400).json({ message: 'Advance must be between 0 and total amount' });
    }

    payment.advanceAmount = advance;
    if (organizerFeePercent != null) {
      const percent = toNumber(organizerFeePercent);
      if (percent < 0 || percent > 100) {
        return res.status(400).json({ message: 'Organizer fee must be between 0 and 100' });
      }
      payment.organizerFeePercent = percent;
    }

    await payment.save();
    return res.json({ message: 'Payment plan updated', payment });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update payment plan', error: error.message });
  }
};

exports.createPaymentLink = async (req, res) => {
  try {
    const { bookingType, bookingId, type } = req.body;
    if (!bookingType || !bookingId || !type) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const payment = await getOrCreatePayment({ bookingType, bookingId });
    if (Number(req.user?.id) !== Number(payment.customerId) && req.user?.role !== 'organizer') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const amountToCharge = resolveAmountToCharge(payment, type);

    const transaction = await PaymentTransaction.create({
      paymentId: payment.id,
      type,
      amount: amountToCharge,
      method: 'online',
      status: 'pending',
      createdBy: req.user?.id,
    });

    const customer = await User.findByPk(payment.customerId, { attributes: ['name', 'email', 'phone'] });

    const razorpay = getRazorpayClient();
    const paymentLink = await razorpay.paymentLink.create({
      amount: Math.round(amountToCharge * 100),
      currency: payment.currency || 'INR',
      description: `${bookingType} booking payment (${type})`,
      reference_id: `PAY-${payment.id}-${transaction.id}`,
      customer: {
        name: customer?.name || 'Customer',
        email: customer?.email || undefined,
        contact: customer?.phone || undefined,
      },
      notify: { sms: !!customer?.phone, email: !!customer?.email },
      callback_url: undefined,
    });

    transaction.razorpayPaymentLinkId = paymentLink.id;
    transaction.razorpayPaymentLinkReferenceId = paymentLink.reference_id;
    await transaction.save();

    return res.json({
      message: 'Payment link created',
      url: paymentLink.short_url,
      transactionId: transaction.id,
      amount: amountToCharge,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to create payment link', error: error.message });
  }
};

exports.createRazorpayOrder = async (req, res) => {
  try {
    const { bookingType, bookingId, type } = req.body;
    if (!bookingType || !bookingId || !type) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const payment = await getOrCreatePayment({ bookingType, bookingId });
    if (Number(req.user?.id) !== Number(payment.customerId) && req.user?.role !== 'organizer') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const amountToCharge = resolveAmountToCharge(payment, type);

    const transaction = await PaymentTransaction.create({
      paymentId: payment.id,
      type,
      amount: amountToCharge,
      method: 'online',
      status: 'pending',
      createdBy: req.user?.id,
    });

    const customer = await User.findByPk(payment.customerId, { attributes: ['name', 'email', 'phone'] });

    const razorpay = getRazorpayClient();
    const order = await razorpay.orders.create({
      amount: Math.round(amountToCharge * 100),
      currency: payment.currency || 'INR',
      receipt: `PAY-${payment.id}-${transaction.id}`,
      notes: {
        bookingType,
        bookingId: String(bookingId),
        paymentId: String(payment.id),
        transactionId: String(transaction.id),
        type,
      },
    });

    transaction.razorpayOrderId = order.id;
    await transaction.save();

    return res.json({
      message: 'Order created',
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      keyId: RAZORPAY_KEY_ID,
      transactionId: transaction.id,
      paymentId: payment.id,
      customer: {
        name: customer?.name || 'Customer',
        email: customer?.email || undefined,
        contact: customer?.phone || undefined,
      },
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to create order', error: error.message });
  }
};

exports.verifyRazorpayPayment = async (req, res) => {
  try {
    const { transactionId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    if (!transactionId || !razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const transaction = await PaymentTransaction.findByPk(transactionId);
    if (!transaction) return res.status(404).json({ message: 'Transaction not found' });

    if (transaction.razorpayOrderId && transaction.razorpayOrderId !== razorpay_order_id) {
      return res.status(400).json({ message: 'Order mismatch' });
    }

    const valid = verifyPaymentSignature({
      orderId: razorpay_order_id,
      paymentId: razorpay_payment_id,
      signature: razorpay_signature,
    });

    if (!valid) {
      return res.status(401).json({ message: 'Invalid signature' });
    }

    transaction.razorpayOrderId = transaction.razorpayOrderId || razorpay_order_id;

    const result = await finalizeSuccessfulTransaction(transaction, {
      razorpayPaymentId: razorpay_payment_id,
    });

    return res.json({ message: 'Payment verified', payment: result.payment, transaction: result.transaction });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to verify payment', error: error.message });
  }
};

exports.markCashPayment = async (req, res) => {
  try {
    const { bookingType, bookingId, amount, type } = req.body;
    if (!bookingType || !bookingId || !amount || !type) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const payment = await getOrCreatePayment({ bookingType, bookingId });

    const transaction = await PaymentTransaction.create({
      paymentId: payment.id,
      type,
      amount,
      method: 'cash',
      status: 'paid',
      paidAt: new Date(),
      createdBy: req.user?.id,
    });

    const total = toNumber(payment.totalAmount);
    const paid = toNumber(payment.paidAmount) + toNumber(amount);
    payment.paidAmount = paid;
    payment.status = computeStatus(total, paid, payment.refundedAmount);
    await payment.save();

    if (payment.status === 'paid') {
      await ensureReceipt(payment);
    }

    try {
      await notifyUser(payment.customerId, 'paymentAlerts', {
        title: 'Payment received',
        body: `Cash payment of Rs ${amount} received.`,
        data: { type: 'payment_cash', paymentId: payment.id, amount },
      });
      if (payment.vendorId) {
        await notifyUser(payment.vendorId, 'paymentAlerts', {
          title: 'Payment update',
          body: `Payment updated for booking ${payment.bookingId}.`,
          data: { type: 'payment_cash', paymentId: payment.id, amount },
        });
      }
      await notifyOrganizers({
        title: 'Cash payment recorded',
        body: `Rs ${amount} cash recorded for booking ${payment.bookingId}.`,
        data: { type: 'payment_cash', paymentId: payment.id, amount },
      });
    } catch (_) {}

    return res.json({ message: 'Cash payment recorded', payment, transaction });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to record cash payment', error: error.message });
  }
};

exports.recordPayout = async (req, res) => {
  try {
    const { paymentId, vendorId, amount, notes } = req.body;
    if (!paymentId || !vendorId || !amount) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const payment = await Payment.findByPk(paymentId);
    if (!payment) return res.status(404).json({ message: 'Payment not found' });

    const payout = await Payout.create({
      paymentId,
      vendorId,
      amount,
      organizerFeePercent: payment.organizerFeePercent,
      status: 'paid',
      paidAt: new Date(),
      notes,
    });

    return res.json({ message: 'Payout recorded', payout });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to record payout', error: error.message });
  }
};

exports.refundPayment = async (req, res) => {
  try {
    const { paymentId, amount, method, notes } = req.body;
    if (!paymentId || !amount) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const result = await recordRefund({
      paymentId,
      amount,
      method,
      createdBy: req.user?.id,
      notes,
    });

    return res.json({ message: 'Refund recorded', payment: result.payment, transaction: result.refundTransaction });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({ message: 'Failed to record refund', error: error.message });
  }
};

exports.razorpayWebhook = async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const payload = req.body;
    const raw = req.rawBody || payload;

    const rawString = Buffer.isBuffer(raw)
      ? raw.toString('utf8')
      : typeof raw === 'string'
        ? raw
        : JSON.stringify(raw);
    const valid = verifyWebhookSignature(rawString, signature);
    if (!valid) {
      return res.status(401).json({ message: 'Invalid signature' });
    }

    const event = payload.event;
    if (event !== 'payment_link.paid') {
      return res.json({ message: 'Event ignored' });
    }

    const paymentLink = payload?.payload?.payment_link?.entity;
    const paymentEntity = payload?.payload?.payment?.entity;
    const paymentLinkId = paymentLink?.id;
    const paymentId = paymentEntity?.id;

    if (!paymentLinkId) {
      return res.status(400).json({ message: 'Missing payment link id' });
    }

    const transaction = await PaymentTransaction.findOne({ where: { razorpayPaymentLinkId: paymentLinkId } });
    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    const result = await finalizeSuccessfulTransaction(transaction, {
      razorpayPaymentId: paymentId || transaction.razorpayPaymentId,
    });

    return res.json({ message: 'Payment updated', payment: result.payment });
  } catch (error) {
    return res.status(500).json({ message: 'Webhook handling failed', error: error.message });
  }
};

exports.downloadReceipt = async (req, res) => {
  try {
    const { paymentId } = req.params;
    const payment = await Payment.findByPk(paymentId);
    if (!payment) return res.status(404).json({ message: 'Payment not found' });

    if (req.user?.role !== 'organizer' && Number(req.user?.id) !== Number(payment.customerId) && Number(req.user?.id) !== Number(payment.vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    if (!payment.receiptNumber && toNumber(payment.paidAmount) > 0) {
      await ensureReceipt(payment);
    }

    const customer = await User.findByPk(payment.customerId, { attributes: ['name', 'email', 'phone'] });

    let bookingLabel = '';
    if (payment.bookingType === 'hall') {
      const booking = await Booking.findByPk(payment.bookingId);
      const hall = booking ? await Hall.findByPk(booking.hallId) : null;
      bookingLabel = hall ? `Hall: ${hall.name}` : `Hall booking #${payment.bookingId}`;
    } else {
      const booking = await VendorBooking.findByPk(payment.bookingId);
      const service = booking ? await VendorService.findByPk(booking.serviceId) : null;
      bookingLabel = service ? `Vendor Service: ${service.name}` : `Vendor booking #${payment.bookingId}`;
    }

    const doc = new PDFDocument({ margin: 50 });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=receipt-${payment.id}.pdf`);
    doc.pipe(res);

    doc.fontSize(18).text('Payment Receipt', { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(`Receipt No: ${payment.receiptNumber || 'N/A'}`);
    doc.text(`Receipt Date: ${payment.receiptIssuedAt ? new Date(payment.receiptIssuedAt).toLocaleString() : 'N/A'}`);
    doc.moveDown();

    doc.text(`Customer: ${customer?.name || 'Customer'}`);
    doc.text(`Email: ${customer?.email || 'N/A'}`);
    doc.text(`Phone: ${customer?.phone || 'N/A'}`);
    doc.moveDown();

    doc.text(bookingLabel);
    doc.text(`Total Amount: Rs ${payment.totalAmount}`);
    doc.text(`Paid Amount: Rs ${payment.paidAmount}`);
    doc.text(`Refunded Amount: Rs ${payment.refundedAmount}`);
    doc.text(`Status: ${payment.status}`);

    doc.end();
  } catch (error) {
    res.status(500).json({ message: 'Failed to generate receipt', error: error.message });
  }
};
