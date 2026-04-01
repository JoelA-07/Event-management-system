const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { createBooking, cancelBooking, getBookedDates, getBookedSlots, getUserBookings } = require('../controllers/bookingController');

router.use(verifyToken);

router.post('/create', createBooking);
router.post('/:id/cancel', requireRole(['customer', 'organizer', 'hall_owner']), cancelBooking);
router.get('/booked-dates/:hallId', getBookedDates);
router.get('/booked-slots/:hallId', getBookedSlots);
router.get('/user/:userId/:role', getUserBookings);

module.exports = router;
