const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const {
  createVendorBooking,
  getVendorBookings,
  getCustomerVendorBookings,
  getVendorBookedSlots,
  getVendorUnavailableSlots,
  addVendorUnavailableSlot,
  deleteVendorUnavailableSlot,
  updateVendorBookingStatus,
} = require('../controllers/vendorBookingController');

router.use(verifyToken);

router.post('/create', requireRole(['customer', 'organizer']), createVendorBooking);
router.get('/vendor/:vendorId', requireRole(['organizer', 'decorator', 'photographer', 'caterer', 'designer', 'mehendi', 'hall_owner']), getVendorBookings);
router.get('/customer/:customerId', requireRole(['customer', 'organizer']), getCustomerVendorBookings);
router.patch('/:id/status', requireRole(['organizer', 'decorator', 'photographer', 'caterer', 'designer', 'mehendi']), updateVendorBookingStatus);
router.get('/vendor/:vendorId/service/:serviceId/booked-slots', requireRole(['customer', 'organizer', 'decorator', 'photographer', 'caterer', 'designer', 'mehendi', 'hall_owner']), getVendorBookedSlots);
router.get('/vendor/:vendorId/service/:serviceId/unavailable-slots', requireRole(['organizer', 'decorator', 'photographer', 'caterer', 'designer', 'mehendi', 'hall_owner']), getVendorUnavailableSlots);
router.post('/vendor/:vendorId/service/:serviceId/unavailable-slots', requireRole(['organizer', 'decorator', 'photographer', 'caterer', 'designer', 'mehendi', 'hall_owner']), addVendorUnavailableSlot);
router.delete('/vendor/unavailable-slots/:id', requireRole(['organizer', 'decorator', 'photographer', 'caterer', 'designer', 'mehendi', 'hall_owner']), deleteVendorUnavailableSlot);

module.exports = router;
