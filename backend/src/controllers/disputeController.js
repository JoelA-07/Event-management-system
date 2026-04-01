const Dispute = require('../models/Dispute');
const Booking = require('../models/Booking');
const VendorBooking = require('../models/VendorBooking');
const Payment = require('../models/Payment');

exports.createDispute = async (req, res) => {
  try {
    const { bookingType, bookingId, paymentId, reason, details } = req.body;
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (!reason) return res.status(400).json({ message: 'reason is required' });

    const dispute = await Dispute.create({
      bookingType: bookingType || null,
      bookingId: bookingId || null,
      paymentId: paymentId || null,
      openedBy: req.user.id,
      reason,
      details,
      status: 'open',
    });

    res.status(201).json({ message: 'Dispute created', dispute });
  } catch (error) {
    res.status(500).json({ message: 'Failed to create dispute', error: error.message });
  }
};

exports.getDisputes = async (req, res) => {
  try {
    const status = req.query.status;
    const where = status ? { status } : undefined;
    const disputes = await Dispute.findAll({ where, order: [['id', 'DESC']] });
    res.json(disputes);
  } catch (error) {
    res.status(500).json({ message: 'Failed to load disputes', error: error.message });
  }
};

exports.getMyDisputes = async (req, res) => {
  try {
    const disputes = await Dispute.findAll({ where: { openedBy: req.user?.id }, order: [['id', 'DESC']] });
    res.json(disputes);
  } catch (error) {
    res.status(500).json({ message: 'Failed to load disputes', error: error.message });
  }
};

exports.resolveDispute = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, resolutionNotes } = req.body || {};
    if (!status || !['resolved', 'rejected', 'in_review'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const dispute = await Dispute.findByPk(id);
    if (!dispute) return res.status(404).json({ message: 'Dispute not found' });

    dispute.status = status;
    dispute.resolutionNotes = resolutionNotes || null;
    dispute.resolvedBy = req.user?.id;
    dispute.resolvedAt = new Date();
    await dispute.save();

    res.json({ message: 'Dispute updated', dispute });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update dispute', error: error.message });
  }
};

exports.linkDisputeContext = async (req, res) => {
  try {
    const { id } = req.params;
    const { bookingType, bookingId, paymentId } = req.body || {};
    const dispute = await Dispute.findByPk(id);
    if (!dispute) return res.status(404).json({ message: 'Dispute not found' });

    if (bookingType && bookingId) {
      if (bookingType === 'hall') {
        const booking = await Booking.findByPk(bookingId);
        if (!booking) return res.status(404).json({ message: 'Hall booking not found' });
      } else if (bookingType === 'vendor') {
        const booking = await VendorBooking.findByPk(bookingId);
        if (!booking) return res.status(404).json({ message: 'Vendor booking not found' });
      }
      dispute.bookingType = bookingType;
      dispute.bookingId = bookingId;
    }

    if (paymentId) {
      const payment = await Payment.findByPk(paymentId);
      if (!payment) return res.status(404).json({ message: 'Payment not found' });
      dispute.paymentId = paymentId;
    }

    await dispute.save();
    res.json({ message: 'Dispute linked', dispute });
  } catch (error) {
    res.status(500).json({ message: 'Failed to link dispute', error: error.message });
  }
};
