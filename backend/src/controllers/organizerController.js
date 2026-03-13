const Booking = require('../models/Booking');
const VendorBooking = require('../models/VendorBooking');
const VendorService = require('../models/VendorService');
const Hall = require('../models/Hall');
const User = require('../models/User');
const sequelize = require('../config/db');
const { Op, fn, col, literal } = require('sequelize');

exports.getOrganizerOverview = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer') {
      return res.status(403).json({ message: 'Organizer access only' });
    }

    const [hallBookings, vendorBookings, vendorServices, halls, users] = await Promise.all([
      Booking.findAll({
        include: [{ model: Hall, attributes: ['name', 'pricePerDay'] }],
        order: [['bookingDate', 'DESC']],
        limit: 10,
      }),
      VendorBooking.findAll({
        include: [{ model: VendorService, attributes: ['name', 'category', 'price'] }],
        order: [['bookingDate', 'DESC']],
        limit: 10,
      }),
      VendorService.count(),
      Hall.count(),
      User.count(),
    ]);

    res.json({
      totals: {
        totalHallBookings: hallBookings.length,
        totalVendorBookings: vendorBookings.length,
        totalVendors: vendorServices,
        totalHalls: halls,
        totalUsers: users,
      },
      recentHallBookings: hallBookings,
      recentVendorBookings: vendorBookings,
    });
  } catch (error) {
    res.status(500).json({ message: 'Error loading organizer overview', error: error.message });
  }
};

exports.getOrganizerAnalytics = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer') {
      return res.status(403).json({ message: 'Organizer access only' });
    }

    const year = Number(req.query.year) || new Date().getFullYear();
    const startDate = new Date(`${year}-01-01`);
    const endDate = new Date(`${year}-12-31`);

    const [hallRevenueRows, vendorRevenueRows] = await Promise.all([
      Booking.findAll({
        attributes: [
          [fn('MONTH', col('bookingDate')), 'month'],
          [fn('SUM', col('Hall.pricePerDay')), 'amount'],
        ],
        include: [{ model: Hall, attributes: [] }],
        where: { bookingDate: { [Op.between]: [startDate, endDate] }, status: { [Op.ne]: 'cancelled' } },
        group: [literal('MONTH(bookingDate)')],
        raw: true,
      }),
      VendorBooking.findAll({
        attributes: [
          [fn('MONTH', col('bookingDate')), 'month'],
          [fn('SUM', col('VendorService.price')), 'amount'],
        ],
        include: [{ model: VendorService, attributes: [] }],
        where: { bookingDate: { [Op.between]: [startDate, endDate] }, status: { [Op.ne]: 'cancelled' } },
        group: [literal('MONTH(bookingDate)')],
        raw: true,
      }),
    ]);

    const monthly = Array.from({ length: 12 }, (_, i) => ({
      month: i + 1,
      hallRevenue: 0,
      vendorRevenue: 0,
      totalRevenue: 0,
    }));

    hallRevenueRows.forEach((row) => {
      const m = Number(row.month);
      const amt = Number(row.amount || 0);
      if (m >= 1 && m <= 12) monthly[m - 1].hallRevenue = amt;
    });
    vendorRevenueRows.forEach((row) => {
      const m = Number(row.month);
      const amt = Number(row.amount || 0);
      if (m >= 1 && m <= 12) monthly[m - 1].vendorRevenue = amt;
    });
    monthly.forEach((m) => {
      m.totalRevenue = Number(m.hallRevenue) + Number(m.vendorRevenue);
    });

    const totals = monthly.reduce(
      (acc, m) => {
        acc.hallRevenue += m.hallRevenue;
        acc.vendorRevenue += m.vendorRevenue;
        acc.totalRevenue += m.totalRevenue;
        return acc;
      },
      { hallRevenue: 0, vendorRevenue: 0, totalRevenue: 0 },
    );

    res.json({
      year,
      totals,
      monthly,
    });
  } catch (error) {
    res.status(500).json({ message: 'Error loading analytics', error: error.message });
  }
};
