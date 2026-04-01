const express = require('express');
const { verifyToken, requireRole } = require('../middleware/auth');
const {
  getPaymentSummary,
  setPaymentPlan,
  createPaymentLink,
  markCashPayment,
  recordPayout,
  refundPayment,
  downloadReceipt,
  razorpayWebhook,
} = require('../controllers/paymentController');

const router = express.Router();

router.get('/booking/:bookingType/:bookingId', verifyToken, getPaymentSummary);
router.patch('/plan/:paymentId', verifyToken, requireRole('organizer'), setPaymentPlan);
router.post('/link', verifyToken, createPaymentLink);
router.post('/mark-cash', verifyToken, requireRole('organizer'), markCashPayment);
router.post('/payouts', verifyToken, requireRole('organizer'), recordPayout);
router.post('/refund', verifyToken, requireRole('organizer'), refundPayment);
router.get('/receipt/:paymentId', verifyToken, downloadReceipt);

router.post(
  '/razorpay/webhook',
  express.raw({ type: '*/*' }),
  (req, res) => {
    try {
      req.rawBody = req.body;
      req.body = JSON.parse(req.body.toString('utf8'));
    } catch (_) {
      req.body = {};
    }
    return razorpayWebhook(req, res);
  }
);

module.exports = router;
