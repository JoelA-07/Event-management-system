const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const {
  createVendorBooking,
  getVendorBookings,
  getCustomerVendorBookings,
} = require('../controllers/vendorBookingController');

router.use(verifyToken);

router.post('/create', requireRole(['customer', 'organizer']), createVendorBooking);
router.get('/vendor/:vendorId', requireRole(['organizer', 'decorator', 'photographer', 'caterer', 'designer', 'mehendi', 'hall_owner']), getVendorBookings);
router.get('/customer/:customerId', requireRole(['customer', 'organizer']), getCustomerVendorBookings);

module.exports = router;
