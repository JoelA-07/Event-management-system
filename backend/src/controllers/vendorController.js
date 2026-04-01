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
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(req.body.vendorId)) {
      return res.status(403).json({ message: 'Cannot add service for another vendor' });
    }

    const isOrganizer = req.user.role === 'organizer';
    const service = await VendorService.create({
      ...req.body,
      approvalStatus: isOrganizer ? 'approved' : 'pending',
      approvedBy: isOrganizer ? req.user.id : null,
      approvedAt: isOrganizer ? new Date() : null,
    });
    res.status(201).json(service);
  } catch (error) {
    res.status(500).json({ message: 'Error adding service', error: error.message });
  }
};

exports.addServiceWithImage = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(req.body.vendorId)) {
      return res.status(403).json({ message: 'Cannot add service for another vendor' });
    }

    const isOrganizer = req.user.role === 'organizer';
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : req.body.imageUrl;
    const payload = {
      ...req.body,
      imageUrl,
      approvalStatus: isOrganizer ? 'approved' : 'pending',
      approvedBy: isOrganizer ? req.user.id : null,
      approvedAt: isOrganizer ? new Date() : null,
    };
    const service = await VendorService.create(payload);
    res.status(201).json(service);
  } catch (error) {
    res.status(500).json({ message: 'Error adding service', error: error.message });
  }
};

exports.updateService = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const { id } = req.params;
    const service = await VendorService.findByPk(id);
    if (!service) return res.status(404).json({ message: 'Service not found' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(service.vendorId)) {
      return res.status(403).json({ message: 'Cannot update another vendor service' });
    }

    const imageUrl = req.file ? `/uploads/${req.file.filename}` : req.body.imageUrl;
    await service.update({
      ...req.body,
      imageUrl: imageUrl ?? service.imageUrl,
    });
    res.json({ message: 'Service updated', service });
  } catch (error) {
    res.status(500).json({ message: 'Error updating service', error: error.message });
  }
};

exports.addServiceImages = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const { id } = req.params;
    const service = await VendorService.findByPk(id);
    if (!service) return res.status(404).json({ message: 'Service not found' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(service.vendorId)) {
      return res.status(403).json({ message: 'Cannot update another vendor service' });
    }

    const files = req.files || [];
    const newUrls = files.map((file) => `/uploads/${file.filename}`);
    const existing = Array.isArray(service.menuOrPortfolio) ? service.menuOrPortfolio : [];
    const maxPortfolio = 10;
    if (existing.length + newUrls.length > maxPortfolio) {
      return res.status(400).json({
        message: `Portfolio limit is ${maxPortfolio} images`,
      });
    }
    const merged = [...existing, ...newUrls];

    await service.update({ menuOrPortfolio: merged });
    res.json({ message: 'Portfolio updated', menuOrPortfolio: merged });
  } catch (error) {
    res.status(500).json({ message: 'Error updating portfolio', error: error.message });
  }
};

exports.removeServiceImage = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const { id } = req.params;
    const { url } = req.body;
    if (!url) {
      return res.status(400).json({ message: 'Missing image url' });
    }

    const service = await VendorService.findByPk(id);
    if (!service) return res.status(404).json({ message: 'Service not found' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(service.vendorId)) {
      return res.status(403).json({ message: 'Cannot update another vendor service' });
    }

    const existing = Array.isArray(service.menuOrPortfolio) ? service.menuOrPortfolio : [];
    const next = existing.filter((item) => item !== url);
    await service.update({ menuOrPortfolio: next });

    // Best-effort delete file from disk if it's a local upload
    if (url.startsWith('/uploads/')) {
      const path = require('path');
      const fs = require('fs');
      const absolutePath = path.join(__dirname, '..', url);
      fs.unlink(absolutePath, () => {});
    }

    res.json({ message: 'Image removed', menuOrPortfolio: next });
  } catch (error) {
    res.status(500).json({ message: 'Error removing image', error: error.message });
  }
};

exports.addMenu = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(req.body.vendorId)) {
      return res.status(403).json({ message: 'Cannot add menu for another vendor' });
    }
    const menu = await CateringMenu.create(req.body);
    res.status(201).json(menu);
  } catch (error) {
    res.status(500).json({ message: 'Error adding menu', error: error.message });
  }
};

exports.addMenuWithImage = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(req.body.vendorId)) {
      return res.status(403).json({ message: 'Cannot add menu for another vendor' });
    }
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : req.body.imageUrl;
    const menu = await CateringMenu.create({ ...req.body, imageUrl });
    res.status(201).json(menu);
  } catch (error) {
    res.status(500).json({ message: 'Error adding menu', error: error.message });
  }
};

exports.getAllVendorServices = async (req, res) => {
  try {
    const isOrganizer = req.user?.role === 'organizer';
    const where = isOrganizer ? undefined : { approvalStatus: 'approved' };
    const services = await VendorService.findAll({ where, order: [['id', 'DESC']] });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching all services', error: error.message });
  }
};

exports.getServicesByCategory = async (req, res) => {
  try {
    const { category } = req.params;
    const isOrganizer = req.user?.role === 'organizer';
    const where = {
      category,
      ...(isOrganizer ? {} : { approvalStatus: 'approved' }),
    };
    const services = await VendorService.findAll({
      where,
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
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }
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
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }
    const menus = await CateringMenu.findAll({
      where: { vendorId },
      order: [['id', 'DESC']],
    });
    res.json(menus);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching menus', error: error.message });
  }
};

exports.getMenusPublic = async (req, res) => {
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
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    await VendorService.destroy({ where: { id: req.params.id } });
    res.json({ message: 'Service removed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting service', error: error.message });
  }
};

exports.deleteMenu = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    await CateringMenu.destroy({ where: { id: req.params.id } });
    res.json({ message: 'Menu removed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting menu', error: error.message });
  }
};

exports.updateMenu = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const { id } = req.params;
    const menu = await CateringMenu.findByPk(id);
    if (!menu) return res.status(404).json({ message: 'Menu not found' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(menu.vendorId)) {
      return res.status(403).json({ message: 'Cannot update menu for another vendor' });
    }
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : req.body.imageUrl;
    await menu.update({
      ...req.body,
      imageUrl: imageUrl ?? menu.imageUrl,
    });
    res.json({ message: 'Menu updated', menu });
  } catch (error) {
    res.status(500).json({ message: 'Error updating menu', error: error.message });
  }
};

exports.orderSample = async (req, res) => {
  try {
    const { customerId, items, deliveryAddress, tastingDate } = req.body;
    if (!customerId || !Array.isArray(items) || items.length === 0 || !deliveryAddress || !tastingDate) {
      return res.status(400).json({ message: 'Missing required sample order fields' });
    }
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(customerId)) {
      return res.status(403).json({ message: 'Cannot place orders for another user' });
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
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }
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
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (req.user.role !== 'organizer' && Number(req.user.id) !== Number(vendorId)) {
      return res.status(403).json({ message: 'Access denied' });
    }
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
