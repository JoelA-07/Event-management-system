const VendorBooking = require('../models/VendorBooking');
const VendorService = require('../models/VendorService');
const { Op } = require('sequelize');

exports.createVendorBooking = async (req, res) => {
  try {
    const { vendorId, serviceId, customerId, bookingDate, notes } = req.body;
    if (!vendorId || !serviceId || !customerId || !bookingDate) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(customerId)) {
      return res.status(403).json({ message: 'Cannot book for another user' });
    }

    const service = await VendorService.findByPk(serviceId);
    if (!service || Number(service.vendorId) !== Number(vendorId)) {
      return res.status(400).json({ message: 'Invalid vendor service' });
    }

    const existing = await VendorBooking.findOne({
      where: {
        vendorId,
        serviceId,
        bookingDate,
        status: { [Op.ne]: 'cancelled' },
      },
    });
    if (existing) {
      return res.status(400).json({ message: 'This service is already booked for the selected date' });
    }

    const booking = await VendorBooking.create({
      vendorId,
      serviceId,
      customerId,
      bookingDate,
      notes,
    });

    res.status(201).json({ message: 'Vendor booking created', booking });
  } catch (error) {
    res.status(500).json({ message: 'Error creating booking', error: error.message });
  }
};

exports.getVendorBookings = async (req, res) => {
  try {
    const { vendorId } = req.params;
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }
    const bookings = await VendorBooking.findAll({
      where: { vendorId },
      order: [['bookingDate', 'DESC']],
    });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching vendor bookings', error: error.message });
  }
};

exports.getCustomerVendorBookings = async (req, res) => {
  try {
    const { customerId } = req.params;
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(customerId)) {
      return res.status(403).json({ message: 'Access denied' });
    }
    const bookings = await VendorBooking.findAll({
      where: { customerId },
      order: [['bookingDate', 'DESC']],
    });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching customer bookings', error: error.message });
  }
};
