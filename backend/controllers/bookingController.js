const Booking = require('../models/Booking');
const Hall = require('../models/Hall');

exports.createBooking = async (req, res) => {
  try {
    const { hallId, customerId, bookingDate } = req.body;

    // 1. Check if hall is already booked for this date
    const existing = await Booking.findOne({ where: { hallId, bookingDate } });
    if (existing) {
      return res.status(400).json({ message: "This date is already booked!" });
    }

    // 2. Create the booking
    const booking = await Booking.create({ hallId, customerId, bookingDate });
    res.status(201).json({ message: "Booking confirmed!", booking });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

exports.getBookedDates = async (req, res) => {
  const { hallId } = req.params;
  const bookings = await Booking.findAll({ where: { hallId }, attributes: ['bookingDate'] });
  res.json(bookings.map(b => b.bookingDate)); // Returns list of strings: ["2024-12-25", ...]
};

exports.getUserBookings = async (req, res) => {
  try {
    const { userId, role } = req.params;
    let bookings;

    if (role === 'customer') {
      // Customers see only their own bookings
      bookings = await Booking.findAll({
        where: { customerId: userId },
        include: [{ model: Hall, attributes: ['name', 'location', 'pricePerDay', 'imageUrl'] }]
      });
    } else if (role === 'organizer') {
      // Organizers see EVERYTHING on the platform
      bookings = await Booking.findAll({
        include: [{ model: Hall, attributes: ['name', 'location', 'pricePerDay'] }]
      });
    } else {
      // Hall Owners see bookings only for THEIR halls
      bookings = await Booking.findAll({
        include: [{ 
          model: Hall, 
          where: { ownerId: userId },
          attributes: ['name', 'pricePerDay'] 
        }]
      });
    }

    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: "Error fetching bookings", error: error.message });
  }
};