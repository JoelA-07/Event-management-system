const VendorBooking = require('../models/VendorBooking');
const VendorService = require('../models/VendorService');
const VendorAvailability = require('../models/VendorAvailability');
const VendorDateLock = require('../models/VendorDateLock');
const Payment = require('../models/Payment');
const sequelize = require('../config/db');
const { withTransactionRetry } = require('../utils/withTransactionRetry');
const { notifyUser, notifyOrganizers } = require('../services/notificationService');
const { recordRefund, toNumber } = require('../services/paymentService');
const { getPagination, isPaginated, buildPageResponse } = require('../utils/pagination');
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

async function lockVendorDate(transaction, vendorId, serviceId, date) {
  try {
    await VendorDateLock.findOrCreate({
      where: { vendorId, serviceId, date },
      defaults: { vendorId, serviceId, date },
      transaction,
    });
  } catch (err) {
    if (err.name !== 'SequelizeUniqueConstraintError') {
      throw err;
    }
  }

  await VendorDateLock.findOne({
    where: { vendorId, serviceId, date },
    transaction,
    lock: transaction.LOCK.UPDATE,
  });
}

exports.createVendorBooking = async (req, res) => {
  try {
    const { vendorId, serviceId, customerId, bookingDate, notes, slotType, startTime, endTime, slotLabel } = req.body;
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

    const normalized = normalizeSlot({ slotType, startTime, endTime, slotLabel });
    if (normalized.slotType === 'hourly' && (!normalized.startTime || !normalized.endTime)) {
      return res.status(400).json({ message: 'Hourly booking requires startTime and endTime' });
    }

    const booking = await withTransactionRetry(sequelize, async (transaction) => {
      await lockVendorDate(transaction, vendorId, serviceId, bookingDate);

      const existingBookings = await VendorBooking.findAll({
        where: { vendorId, serviceId, bookingDate, status: { [Op.ne]: 'cancelled' } },
        transaction,
      });
      const conflictBooking = existingBookings.find((b) => hasOverlap(b, normalized));
      if (conflictBooking) {
        const err = new Error('This slot is already booked');
        err.statusCode = 400;
        throw err;
      }

      const unavailable = await VendorAvailability.findAll({
        where: { vendorId, serviceId, date: bookingDate },
        transaction,
      });
      const conflictAvailability = unavailable.find((b) => hasOverlap(b, normalized));
      if (conflictAvailability) {
        const err = new Error('Vendor is unavailable for this slot');
        err.statusCode = 400;
        throw err;
      }

      return VendorBooking.create(
        {
          vendorId,
          serviceId,
          customerId,
          bookingDate,
          notes,
          slotType: normalized.slotType,
          startTime: normalized.startTime,
          endTime: normalized.endTime,
        },
        { transaction }
      );
    });

    try {
      await notifyUser(customerId, 'bookingAlerts', {
        title: 'Vendor booking confirmed',
        body: `Your vendor booking for ${bookingDate} is confirmed.`,
        data: { type: 'vendor_booking_confirmed', bookingId: booking.id, vendorId, serviceId, bookingDate },
      });
      await notifyUser(vendorId, 'bookingAlerts', {
        title: 'New booking received',
        body: `You have a new booking on ${bookingDate}.`,
        data: { type: 'vendor_booking_created', bookingId: booking.id, vendorId, serviceId, bookingDate },
      });
      await notifyOrganizers({
        title: 'New vendor booking',
        body: `A vendor booking was created for ${bookingDate}.`,
        data: { type: 'vendor_booking_created', bookingId: booking.id, vendorId, serviceId, bookingDate, customerId },
      });
    } catch (notifyError) {
      console.error('Failed to send vendor booking notifications:', notifyError.message);
    }

    res.status(201).json({ message: 'Vendor booking created', booking });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    const message = statusCode === 500 ? 'Error creating booking' : error.message;
    res.status(statusCode).json({ message, error: statusCode === 500 ? error.message : undefined });
  }
};

exports.cancelVendorBooking = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason, refundAmount, refundMethod, autoRefund } = req.body || {};

    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const booking = await VendorBooking.findByPk(id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    let allowed = false;
    if (req.user.role === 'organizer') {
      allowed = true;
    } else if (req.user.role === 'customer') {
      allowed = Number(req.user.id) === Number(booking.customerId);
    } else {
      allowed = Number(req.user.id) === Number(booking.vendorId);
    }

    if (!allowed) return res.status(403).json({ message: 'Access denied' });
    if (booking.status === 'cancelled') return res.json({ message: 'Already cancelled', booking });

    booking.status = 'cancelled';
    booking.cancelledAt = new Date();
    booking.cancelledBy = req.user.id;
    booking.cancelReason = reason || null;
    await booking.save();

    let refundResult = null;
    if (req.user.role === 'organizer') {
      const payment = await Payment.findOne({ where: { bookingType: 'vendor', bookingId: booking.id } });
      if (payment) {
        const refundable = Math.max(toNumber(payment.paidAmount) - toNumber(payment.refundedAmount), 0);
        const shouldRefund = autoRefund || (refundAmount != null && toNumber(refundAmount) > 0);
        if (shouldRefund && refundable > 0) {
          const amount = autoRefund ? refundable : refundAmount;
          refundResult = await recordRefund({
            paymentId: payment.id,
            amount,
            method: refundMethod || 'manual',
            createdBy: req.user.id,
            notes: reason,
          });
        }
      }
    }

    try {
      await notifyUser(booking.customerId, 'bookingAlerts', {
        title: 'Vendor booking cancelled',
        body: `Your vendor booking for ${booking.bookingDate} was cancelled.`,
        data: { type: 'vendor_booking_cancelled', bookingId: booking.id, vendorId: booking.vendorId, serviceId: booking.serviceId, bookingDate: booking.bookingDate },
      });
      await notifyUser(booking.vendorId, 'bookingAlerts', {
        title: 'Vendor booking cancelled',
        body: `Booking ${booking.id} was cancelled.`,
        data: { type: 'vendor_booking_cancelled', bookingId: booking.id },
      });
      await notifyOrganizers({
        title: 'Vendor booking cancelled',
        body: `Vendor booking ${booking.id} was cancelled.`,
        data: { type: 'vendor_booking_cancelled', bookingId: booking.id },
      });
    } catch (_) {}

    return res.json({ message: 'Vendor booking cancelled', booking, refund: refundResult });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    res.status(statusCode).json({ message: 'Failed to cancel booking', error: error.message });
  }
};

exports.getVendorBookings = async (req, res) => {
  try {
    const { vendorId } = req.params;
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    if (isPaginated(req.query)) {
      const { page, limit, offset } = getPagination(req.query);
      const result = await VendorBooking.findAndCountAll({ where: { vendorId }, order: [['id', 'DESC']], limit, offset });
      return res.json(buildPageResponse({ rows: result.rows, count: result.count, page, limit }));
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

    if (isPaginated(req.query)) {
      const { page, limit, offset } = getPagination(req.query);
      const result = await VendorBooking.findAndCountAll({ where: { customerId }, order: [['id', 'DESC']], limit, offset });
      return res.json(buildPageResponse({ rows: result.rows, count: result.count, page, limit }));
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

exports.getVendorBookedSlots = async (req, res) => {
  try {
    const { vendorId, serviceId } = req.params;
    const { date } = req.query;
    if (!date) return res.status(400).json({ message: 'date query param is required' });
    const bookings = await VendorBooking.findAll({
      where: { vendorId, serviceId, bookingDate: date, status: { [Op.ne]: 'cancelled' } },
      attributes: ['id', 'slotType', 'startTime', 'endTime', 'status'],
      order: [['startTime', 'ASC']],
    });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching vendor slots', error: error.message });
  }
};

exports.getVendorUnavailableSlots = async (req, res) => {
  try {
    const { vendorId, serviceId } = req.params;
    const { date } = req.query;
    if (!date) return res.status(400).json({ message: 'date query param is required' });
    const slots = await VendorAvailability.findAll({
      where: { vendorId, serviceId, date },
      attributes: ['id', 'slotType', 'startTime', 'endTime', 'reason'],
      order: [['startTime', 'ASC']],
    });
    res.json(slots);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching vendor unavailable slots', error: error.message });
  }
};

exports.addVendorUnavailableSlot = async (req, res) => {
  try {
    const { vendorId, serviceId } = req.params;
    const { date, slotType, startTime, endTime, slotLabel, reason } = req.body;
    if (!date) return res.status(400).json({ message: 'date is required' });
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const normalized = normalizeSlot({ slotType, startTime, endTime, slotLabel });
    const entry = await withTransactionRetry(sequelize, async (transaction) => {
      await lockVendorDate(transaction, vendorId, serviceId, date);

      const existing = await VendorAvailability.findAll({
        where: { vendorId, serviceId, date },
        transaction,
      });
      const conflict = existing.find((b) => hasOverlap(b, normalized));
      if (conflict) {
        const err = new Error('Slot already blocked');
        err.statusCode = 400;
        throw err;
      }

      return VendorAvailability.create(
        {
          vendorId,
          serviceId,
          date,
          slotType: normalized.slotType,
          startTime: normalized.startTime,
          endTime: normalized.endTime,
          reason,
        },
        { transaction }
      );
    });

    res.status(201).json(entry);
  } catch (error) {
    const statusCode = error.statusCode || 500;
    const message = statusCode === 500 ? 'Error blocking slot' : error.message;
    res.status(statusCode).json({ message, error: statusCode === 500 ? error.message : undefined });
  }
};

exports.deleteVendorUnavailableSlot = async (req, res) => {
  try {
    const { id } = req.params;
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const entry = await VendorAvailability.findByPk(id);
    if (!entry) return res.status(404).json({ message: 'Slot not found' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(entry.vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }
    await VendorAvailability.destroy({ where: { id } });
    res.json({ message: 'Slot unblocked' });
  } catch (error) {
    res.status(500).json({ message: 'Error removing blocked slot', error: error.message });
  }
};

exports.updateVendorBookingStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (!status) return res.status(400).json({ message: 'status is required' });

    const allowed = ['pending', 'confirmed', 'completed', 'cancelled'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const booking = await VendorBooking.findByPk(id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(booking.vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    booking.status = status;
    await booking.save();
    try {
      await notifyUser(booking.customerId, 'bookingAlerts', {
        title: 'Booking status updated',
        body: `Your vendor booking status is now ${status}.`,
        data: { type: 'vendor_booking_status', bookingId: booking.id, status },
      });
      await notifyUser(booking.vendorId, 'bookingAlerts', {
        title: 'Booking status updated',
        body: `Booking ${booking.id} status is now ${status}.`,
        data: { type: 'vendor_booking_status', bookingId: booking.id, status },
      });
      await notifyOrganizers({
        title: 'Vendor booking status changed',
        body: `Booking ${booking.id} status is now ${status}.`,
        data: { type: 'vendor_booking_status', bookingId: booking.id, status },
      });
    } catch (notifyError) {
      console.error('Failed to send booking status notifications:', notifyError.message);
    }
    res.json({ message: 'Booking status updated', booking });
  } catch (error) {
    res.status(500).json({ message: 'Error updating booking status', error: error.message });
  }
};
