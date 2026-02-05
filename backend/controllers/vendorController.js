const VendorService = require('../models/VendorService');
const User = require('../models/User');
const SampleOrder = require('../models/SampleOrder');

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
};