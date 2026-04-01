const Payment = require('../models/Payment');
const PaymentTransaction = require('../models/PaymentTransaction');

function toNumber(value) {
  const num = Number(value || 0);
  return Number.isNaN(num) ? 0 : num;
}

function computeStatus(total, paid, refunded) {
  const netPaid = Math.max(toNumber(paid) - toNumber(refunded), 0);
  if (netPaid <= 0 && toNumber(refunded) > 0) return 'refunded';
  if (netPaid >= toNumber(total) && toNumber(total) > 0) return 'paid';
  if (netPaid > 0) return 'partial';
  return 'pending';
}

async function recordRefund({ paymentId, amount, method, createdBy, notes, transaction }) {
  const payment = await Payment.findByPk(paymentId, { transaction });
  if (!payment) {
    const err = new Error('Payment not found');
    err.statusCode = 404;
    throw err;
  }

  const totalPaid = toNumber(payment.paidAmount);
  const refunded = toNumber(payment.refundedAmount);
  const maxRefundable = Math.max(totalPaid - refunded, 0);
  const refundAmount = toNumber(amount);

  if (refundAmount <= 0) {
    const err = new Error('Refund amount must be greater than 0');
    err.statusCode = 400;
    throw err;
  }
  if (refundAmount > maxRefundable) {
    const err = new Error('Refund amount exceeds refundable balance');
    err.statusCode = 400;
    throw err;
  }

  const refundTransaction = await PaymentTransaction.create(
    {
      paymentId: payment.id,
      type: 'refund',
      amount: refundAmount,
      method: method || 'manual',
      status: 'paid',
      paidAt: new Date(),
      createdBy,
      notes,
    },
    { transaction },
  );

  payment.refundedAmount = toNumber(payment.refundedAmount) + refundAmount;
  payment.status = computeStatus(payment.totalAmount, payment.paidAmount, payment.refundedAmount);
  await payment.save({ transaction });

  return { payment, refundTransaction };
}

module.exports = {
  toNumber,
  computeStatus,
  recordRefund,
};
