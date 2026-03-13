const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { createBooking, getBookedDates, getBookedSlots, getUserBookings } = require('../controllers/bookingController');

router.use(verifyToken);

router.post('/create', createBooking);
router.get('/booked-dates/:hallId', getBookedDates);
router.get('/booked-slots/:hallId', getBookedSlots);
router.get('/user/:userId/:role', getUserBookings);

module.exports = router;
