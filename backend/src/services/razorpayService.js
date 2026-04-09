const Razorpay = require('razorpay');
const crypto = require('crypto');
const {
  RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET,
  RAZORPAY_WEBHOOK_SECRET,
  RAZORPAY_ALLOW_UNVERIFIED_WEBHOOKS,
} = require('../config/env');

function getRazorpayClient() {
  if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
    throw new Error('Razorpay is not configured');
  }
  return new Razorpay({
    key_id: RAZORPAY_KEY_ID,
    key_secret: RAZORPAY_KEY_SECRET,
  });
}

function verifyWebhookSignature(payload, signature) {
  if (RAZORPAY_ALLOW_UNVERIFIED_WEBHOOKS && process.env.NODE_ENV !== 'production') {
    return true;
  }
  if (!RAZORPAY_WEBHOOK_SECRET) {
    throw new Error('Razorpay webhook secret not configured');
  }
  const expected = crypto
    .createHmac('sha256', RAZORPAY_WEBHOOK_SECRET)
    .update(payload)
    .digest('hex');
  return expected === signature;
}

function verifyPaymentSignature({ orderId, paymentId, signature }) {
  if (!RAZORPAY_KEY_SECRET) {
    throw new Error('Razorpay key secret not configured');
  }
  const data = `${orderId}|${paymentId}`;
  const expected = crypto
    .createHmac('sha256', RAZORPAY_KEY_SECRET)
    .update(data)
    .digest('hex');
  return expected === signature;
}

module.exports = {
  getRazorpayClient,
  verifyWebhookSignature,
  verifyPaymentSignature,
};
