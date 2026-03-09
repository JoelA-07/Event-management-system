const { Op } = require('sequelize');
const VendorService = require('../models/VendorService');
const SampleOrder = require('../models/SampleOrder');
const CateringMenu = require('../models/CateringMenu');
const Booking = require('../models/Booking');
const Hall = require('../models/Hall');
const User = require('../models/User');

const EVENT_KEYWORDS = {
  wedding: ['wedding', 'marriage', 'engagement'],
  reception: ['reception'],
  birthday: ['birthday', 'bday'],
  surprise: ['surprise'],
  outing: ['outing', 'outdoor', 'trip', 'picnic'],
  funeral: ['funeral', 'memorial'],
  corporate: ['corporate', 'conference', 'seminar', 'office'],
};

function buildEventSearchWhere(eventType) {
  const normalized = String(eventType || '').toLowerCase();
  const keywords = EVENT_KEYWORDS[normalized] || [normalized];
  return {
    [Op.or]: keywords.flatMap((word) => [
      { name: { [Op.like]: `%${word}%` } },
      { description: { [Op.like]: `%${word}%` } },
    ]),
  };
}

exports.addService = async (req, res) => {
  try {
    const service = await VendorService.create(req.body);
    res.status(201).json(service);
  } catch (error) {
    res.status(500).json({ message: 'Error adding service', error: error.message });
  }
};

exports.addMenu = async (req, res) => {
  try {
    const menu = await CateringMenu.create(req.body);
    res.status(201).json(menu);
  } catch (error) {
    res.status(500).json({ message: 'Error adding menu', error: error.message });
  }
};

exports.getAllVendorServices = async (_req, res) => {
  try {
    const services = await VendorService.findAll({ order: [['id', 'DESC']] });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching all services', error: error.message });
  }
};

exports.getServicesByCategory = async (req, res) => {
  try {
    const { category } = req.params;
    const services = await VendorService.findAll({
      where: { category },
      order: [['id', 'DESC']],
    });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching services', error: error.message });
  }
};

exports.getMyServices = async (req, res) => {
  try {
    const { vendorId } = req.params;
    const services = await VendorService.findAll({
      where: { vendorId },
      order: [['id', 'DESC']],
    });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching your services', error: error.message });
  }
};

exports.getMyMenus = async (req, res) => {
  try {
    const { vendorId } = req.params;
    const menus = await CateringMenu.findAll({
      where: { vendorId },
      order: [['id', 'DESC']],
    });
    res.json(menus);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching menus', error: error.message });
  }
};

exports.deleteService = async (req, res) => {
  try {
    await VendorService.destroy({ where: { id: req.params.id } });
    res.json({ message: 'Service removed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting service', error: error.message });
  }
};

exports.deleteMenu = async (req, res) => {
  try {
    await CateringMenu.destroy({ where: { id: req.params.id } });
    res.json({ message: 'Menu removed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting menu', error: error.message });
  }
};

exports.orderSample = async (req, res) => {
  try {
    const { customerId, items, deliveryAddress, tastingDate } = req.body;
    if (!customerId || !Array.isArray(items) || items.length === 0 || !deliveryAddress || !tastingDate) {
      return res.status(400).json({ message: 'Missing required sample order fields' });
    }

    const orders = await Promise.all(
      items.map((item) =>
        SampleOrder.create({
          customerId,
          vendorId: item.vendorId,
          menuId: item.menuId,
          deliveryAddress,
          tastingDate,
        }),
      ),
    );

    res.status(201).json({ message: 'Sample orders placed!', orders });
  } catch (error) {
    res.status(500).json({ message: 'Error placing sample order', error: error.message });
  }
};

exports.getVendorDashboardStats = async (req, res) => {
  try {
    const { vendorId } = req.params;
    const vendor = await User.findByPk(vendorId, { attributes: ['id', 'role'] });
    if (!vendor) {
      return res.status(404).json({ message: 'Vendor not found' });
    }

    const serviceCount = await VendorService.count({ where: { vendorId } });
    const sampleCount = await SampleOrder.count({ where: { vendorId, status: 'pending' } });
    const menuCount = await CateringMenu.count({ where: { vendorId } });

    // Revenue approximation until payment and commission tables are added.
    let totalEarnings = 0;
    if (vendor.role === 'hall_owner') {
      const hallIds = await Hall.findAll({ where: { ownerId: vendorId }, attributes: ['id'] });
      if (hallIds.length > 0) {
        const ids = hallIds.map((h) => h.id);
        const bookings = await Booking.findAll({
          where: { hallId: { [Op.in]: ids } },
          include: [{ model: Hall, attributes: ['pricePerDay'] }],
        });
        totalEarnings = bookings.reduce((sum, booking) => {
          const amount = Number(booking.Hall?.pricePerDay || 0);
          return sum + amount;
        }, 0);
      }
    }

    res.json({
      totalEarnings,
      activeServices: serviceCount,
      activeMenus: menuCount,
      sampleRequests: sampleCount,
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching stats', error: error.message });
  }
};

exports.getVendorSampleOrders = async (req, res) => {
  try {
    const { vendorId } = req.params;
    const orders = await SampleOrder.findAll({
      where: { vendorId },
      order: [['tastingDate', 'ASC']],
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching samples', error: error.message });
  }
};

exports.getEventRecommendations = async (req, res) => {
  try {
    const { eventType } = req.params;
    const where = buildEventSearchWhere(eventType);
    const services = await VendorService.findAll({
      where,
      limit: 20,
      order: [['id', 'DESC']],
    });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching event recommendations', error: error.message });
  }
};
