const Booking = require('../models/Booking');
const Hall = require('../models/Hall');
const BookingLock = require('../models/BookingLock');
const sequelize = require('../config/db');
const { withTransactionRetry } = require('../utils/withTransactionRetry');
const { notifyUser, notifyOrganizers } = require('../services/notificationService');
const { Op } = require('sequelize');

const SLOT_PRESETS = {
  morning: { start: '08:00:00', end: '14:00:00' },
  evening: { start: '15:00:00', end: '22:00:00' },
};

function toMinutes(timeStr) {
  if (!timeStr) return null;
  const [h, m] = timeStr.split(':').map(Number);
  return h * 60 + m;
}

function normalizeSlot({ slotType, startTime, endTime, slotLabel }) {
  const type = slotType || 'full_day';
  if (type === 'full_day') {
    return { slotType: 'full_day', startTime: '00:00:00', endTime: '23:59:59' };
  }

  if (type === 'half_day') {
    const preset = SLOT_PRESETS[slotLabel] || SLOT_PRESETS.morning;
    return { slotType: 'half_day', startTime: preset.start, endTime: preset.end };
  }

  if (type === 'hourly') {
    return { slotType: 'hourly', startTime, endTime };
  }

  return { slotType: 'full_day', startTime: '00:00:00', endTime: '23:59:59' };
}

function hasOverlap(existing, next) {
  if (existing.slotType === 'full_day' || next.slotType === 'full_day') return true;
  const existingStart = toMinutes(existing.startTime);
  const existingEnd = toMinutes(existing.endTime);
  const nextStart = toMinutes(next.startTime);
  const nextEnd = toMinutes(next.endTime);
  if (existingStart == null || existingEnd == null || nextStart == null || nextEnd == null) return true;
  return nextStart < existingEnd && nextEnd > existingStart;
}

async function lockHallDate(transaction, hallId, bookingDate) {
  try {
    await BookingLock.findOrCreate({
      where: { hallId, bookingDate },
      defaults: { hallId, bookingDate },
      transaction,
    });
  } catch (err) {
    if (err.name !== 'SequelizeUniqueConstraintError') {
      throw err;
    }
  }

  await BookingLock.findOne({
    where: { hallId, bookingDate },
    transaction,
    lock: transaction.LOCK.UPDATE,
  });
}

exports.createBooking = async (req, res) => {
  try {
    const { hallId, customerId, bookingDate, slotType, startTime, endTime, slotLabel } = req.body;
    if (!hallId || !customerId || !bookingDate) {
      return res.status(400).json({ message: "Missing required booking fields" });
    }
    if (!req.user) {
      return res.status(401).json({ message: "Unauthorized" });
    }
    if (req.user.role !== 'customer' && req.user.role !== 'organizer') {
      return res.status(403).json({ message: "Only customers can place bookings" });
    }
    if (req.user.role === 'customer' && Number(req.user.id) !== Number(customerId)) {
      return res.status(403).json({ message: "Cannot book for another user" });
    }

    const normalized = normalizeSlot({ slotType, startTime, endTime, slotLabel });
    if (normalized.slotType === 'hourly' && (!normalized.startTime || !normalized.endTime)) {
      return res.status(400).json({ message: "Hourly booking requires startTime and endTime" });
    }

    const booking = await withTransactionRetry(sequelize, async (transaction) => {
      await lockHallDate(transaction, hallId, bookingDate);

      const existing = await Booking.findAll({
        where: {
          hallId,
          bookingDate,
          status: { [Op.ne]: 'cancelled' },
        },
        transaction,
      });

      const conflict = existing.find((b) => hasOverlap(b, normalized));
      if (conflict) {
        const err = new Error('This time slot is already booked!');
        err.statusCode = 400;
        throw err;
      }

      return Booking.create(
        {
          hallId,
          customerId,
          bookingDate,
          slotType: normalized.slotType,
          startTime: normalized.startTime,
          endTime: normalized.endTime,
        },
        { transaction }
      );
    });

    try {
      await notifyUser(customerId, 'bookingAlerts', {
        title: 'Booking confirmed',
        body: `Your booking for ${bookingDate} is confirmed.`,
        data: { type: 'booking_confirmed', bookingId: booking.id, hallId, bookingDate },
      });
      await notifyOrganizers({
        title: 'New booking',
        body: `A new hall booking was created for ${bookingDate}.`,
        data: { type: 'booking_created', bookingId: booking.id, hallId, bookingDate, customerId },
      });
    } catch (notifyError) {
      console.error('Failed to send booking notifications:', notifyError.message);
    }

    res.status(201).json({ message: "Booking confirmed!", booking });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    const message = statusCode === 500 ? "Server error" : error.message;
    res.status(statusCode).json({ message, error: statusCode === 500 ? error.message : undefined });
  }
};

exports.getBookedDates = async (req, res) => {
  const { hallId } = req.params;
  const bookings = await Booking.findAll({
    where: { hallId, status: { [Op.ne]: 'cancelled' }, slotType: 'full_day' },
    attributes: ['bookingDate'],
  });
  res.json(bookings.map(b => b.bookingDate)); // Returns list of strings: ["2024-12-25", ...]
};

exports.getBookedSlots = async (req, res) => {
  try {
    const { hallId } = req.params;
    const { date } = req.query;
    if (!date) {
      return res.status(400).json({ message: "date query param is required (YYYY-MM-DD)" });
    }
    const bookings = await Booking.findAll({
      where: {
        hallId,
        bookingDate: date,
        status: { [Op.ne]: 'cancelled' },
      },
      attributes: ['id', 'slotType', 'startTime', 'endTime', 'status'],
      order: [['startTime', 'ASC']],
    });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: "Error fetching slots", error: error.message });
  }
};

exports.getUserBookings = async (req, res) => {
  try {
    const { userId, role } = req.params;
    if (!req.user) {
      return res.status(401).json({ message: "Unauthorized" });
    }
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(userId)) {
      return res.status(403).json({ message: "Access denied" });
    }
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
