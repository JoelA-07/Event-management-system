const VendorService = require('../models/VendorService');
const User = require('../models/User');
const SampleOrder = require('../models/SampleOrder');
const CateringMenu = require('../models/CateringMenu');
const SampleOrder = require('../models/SampleOrder');
const sequelize = require('../config/db');

// Add a new service (For Vendors)
exports.addService = async (req, res) => {
  try {
    const service = await VendorService.create(req.body);
    res.status(201).json(service);
  } catch (error) {
    res.status(500).json({ message: "Error adding service", error: error.message });
  }
};

// Get services by category (For Customers)
exports.getServicesByCategory = async (req, res) => {
  try {
    const { category } = req.params;
    const services = await VendorService.findAll({ where: { category } });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: "Error fetching services" });
  }
};

// Get services for a SPECIFIC vendor (for their own dashboard)
exports.getMyServices = async (req, res) => {
  try {
    const { vendorId } = req.params;
    const services = await VendorService.findAll({ where: { vendorId } });
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: "Error fetching your services" });
  }
};

// Delete a service
exports.deleteService = async (req, res) => {
  try {
    await VendorService.destroy({ where: { id: req.params.id } });
    res.json({ message: "Service removed successfully" });
  } catch (error) {
    res.status(500).json({ message: "Error deleting service" });
  }
};

// Get every single vendor service across all categories
exports.getAllVendorServices = async (req, res) => {
  try {
    const services = await VendorService.findAll();
    res.json(services);
  } catch (error) {
    res.status(500).json({ message: "Error fetching all services" });
  }
};


exports.orderSample = async (req, res) => {
  try {
    const { customerId, items, deliveryAddress, tastingDate } = req.body;

    // Create multiple orders for each caterer in the cart
    const orders = await Promise.all(items.map(item => {
      return SampleOrder.create({
        customerId,
        vendorId: item.vendorId,
        menuId: item.menuId,
        deliveryAddress,
        tastingDate
      });
    }));

    res.status(201).json({ message: "Sample orders placed!", orders });
  } catch (error) {
    res.status(500).json({ message: "Error placing sample order", error: error.message });
  }

exports.getVendorDashboardStats = async (req, res) => {
  try {
    const { vendorId } = req.params;

    // Count real active menus
    const menuCount = await CateringMenu.count({ where: { vendorId } });

    // Count real sample requests
    const sampleCount = await SampleOrder.count({ where: { vendorId, status: 'pending' } });

    // Dummy revenue for now (logic would sum completed bookings)
    const totalEarnings = "2.4L"; 

    res.json({
      totalEarnings,
      platesServed: "1.5k",
      activeMenus: menuCount,
      sampleRequests: sampleCount
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Fetch Sample Orders for the specific Caterer
exports.getVendorSampleOrders = async (req, res) => {
  try {
    const { vendorId } = req.params;
    const orders = await SampleOrder.findAll({
      where: { vendorId },
      order: [['tastingDate', 'ASC']]
    });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

};