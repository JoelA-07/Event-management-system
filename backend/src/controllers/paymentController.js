const Booking = require('../models/Booking');
const VendorBooking = require('../models/VendorBooking');
const Hall = require('../models/Hall');
const VendorService = require('../models/VendorService');
const User = require('../models/User');
const Payment = require('../models/Payment');
const PaymentTransaction = require('../models/PaymentTransaction');
const Payout = require('../models/Payout');
const { getRazorpayClient, verifyWebhookSignature } = require('../services/razorpayService');
const { notifyUser, notifyOrganizers } = require('../services/notificationService');

function toNumber(value) {
  const num = Number(value || 0);
  return Number.isNaN(num) ? 0 : num;
}

function computeStatus(total, paid) {
  if (paid >= total && total > 0) return 'paid';
  if (paid > 0) return 'partial';
  return 'pending';
}

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

exports.getPaymentSummary = async (req, res) => {
  try {
    const { bookingType, bookingId } = req.params;
    const payment = await getOrCreatePayment({ bookingType, bookingId });

    if (req.user?.role !== 'organizer' && Number(req.user?.id) !== Number(payment.customerId) && Number(req.user?.id) !== Number(payment.vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const transactions = await PaymentTransaction.findAll({ where: { paymentId: payment.id }, order: [['id', 'DESC']] });
    const payouts = await Payout.findAll({ where: { paymentId: payment.id }, order: [['id', 'DESC']] });

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

    const total = toNumber(payment.totalAmount);
    const advance = toNumber(payment.advanceAmount);
    const paid = toNumber(payment.paidAmount);
    const remaining = Math.max(total - paid, 0);

    let amountToCharge = 0;
    if (type === 'advance') {
      if (advance <= 0) return res.status(400).json({ message: 'Advance is not set' });
      if (paid >= advance) return res.status(400).json({ message: 'Advance already paid' });
      amountToCharge = Math.min(advance - paid, remaining);
    } else if (type === 'balance') {
      if (remaining <= 0) return res.status(400).json({ message: 'Payment already completed' });
      amountToCharge = remaining;
    } else {
      return res.status(400).json({ message: 'Invalid payment type' });
    }

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
    payment.status = computeStatus(total, paid);
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

    if (transaction.status === 'paid') {
      return res.json({ message: 'Already processed' });
    }

    transaction.status = 'paid';
    transaction.razorpayPaymentId = paymentId || transaction.razorpayPaymentId;
    transaction.paidAt = new Date();
    await transaction.save();

    const payment = await Payment.findByPk(transaction.paymentId);
    if (payment) {
      const total = toNumber(payment.totalAmount);
      const paid = toNumber(payment.paidAmount) + toNumber(transaction.amount);
      payment.paidAmount = paid;
      payment.status = computeStatus(total, paid);
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

    return res.json({ message: 'Payment updated' });
  } catch (error) {
    return res.status(500).json({ message: 'Webhook handling failed', error: error.message });
  }
};
