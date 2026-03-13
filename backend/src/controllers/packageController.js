const Package = require('../models/Package');
const { Op } = require('sequelize');

const EVENT_KEYWORDS = {
  wedding: ['wedding', 'marriage', 'engagement'],
  reception: ['reception'],
  birthday: ['birthday', 'bday'],
  surprise: ['surprise'],
  outing: ['outing', 'outdoor', 'trip', 'picnic'],
  funeral: ['funeral', 'memorial'],
  corporate: ['corporate', 'conference', 'seminar', 'office'],
};

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
    const eventType = String(req.query.eventType || '').toLowerCase().trim();
    let where = undefined;

    if (eventType) {
      const keywords = EVENT_KEYWORDS[eventType] || [eventType];
      where = {
        [Op.or]: keywords.flatMap((word) => [
          { title: { [Op.like]: `%${word}%` } },
          { description: { [Op.like]: `%${word}%` } },
        ]),
      };
    }

    const packages = await Package.findAll({ where, order: [['id', 'DESC']] });
    res.json(packages);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching packages', error: error.message });
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
