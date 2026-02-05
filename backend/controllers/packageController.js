const Package = require('../models/Package');

// 1. Create a new bundle (Organizer only)
exports.addPackage = async (req, res) => {
  try {
    const { organizerId, title, description, totalPrice, serviceIds, imageUrl } = req.body;

    const newPackage = await Package.create({
      organizerId,
      title,
      description,
      totalPrice,
      serviceIds, // Sequelize handles this as a JSON string in MySQL
      imageUrl
    });

    res.status(201).json({ message: "Package created successfully!", newPackage });
  } catch (error) {
    res.status(500).json({ message: "Error creating package", error: error.message });
  }
};

// 2. Get all packages (For Customer Dashboard)
exports.getAllPackages = async (req, res) => {
  try {
    const packages = await Package.findAll();
    res.json(packages);
  } catch (error) {
    res.status(500).json({ message: "Error fetching packages" });
  }
};

// 3. Delete a package
exports.deletePackage = async (req, res) => {
  try {
    await Package.destroy({ where: { id: req.params.id } });
    res.json({ message: "Package deleted" });
  } catch (error) {
    res.status(500).json({ message: "Error deleting package" });
  }
};