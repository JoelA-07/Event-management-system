const express = require('express');
const router = express.Router();
const { createBooking, getBookedDates,getUserBookings } = require('../controllers/bookingController');

router.post('/create', createBooking);
router.get('/booked-dates/:hallId', getBookedDates);
router.get('/user/:userId/:role', getUserBookings);

module.exports = router;