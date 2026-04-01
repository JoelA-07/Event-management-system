const Hall = require('../models/Hall');
const { Op } = require('sequelize');
const { getPagination, isPaginated, buildPageResponse } = require('../utils/pagination');

const EVENT_KEYWORDS = {
  wedding: ['wedding', 'marriage', 'engagement'],
  reception: ['reception'],
  birthday: ['birthday', 'bday'],
  surprise: ['surprise'],
  outing: ['outing', 'outdoor', 'trip', 'picnic'],
  funeral: ['funeral', 'memorial'],
  corporate: ['corporate', 'conference', 'seminar', 'office'],
};

// 1. Add a new Hall
exports.addHall = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const { name, location, capacity, pricePerDay, description, ownerId } = req.body;

    const isOrganizer = req.user.role === 'organizer';

    // Get the filename from multer
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : '/uploads/default.jpg';

    const hall = await Hall.create({
      name,
      location,
      capacity,
      pricePerDay,
      description,
      ownerId,
      imageUrl: imageUrl, // Save path to DB
      approvalStatus: isOrganizer ? 'approved' : 'pending',
      approvedBy: isOrganizer ? req.user.id : null,
      approvedAt: isOrganizer ? new Date() : null,
    });
    res.status(201).json(hall);
  } catch (error) {
    res.status(500).json({ message: 'Error adding hall', error: error.message });
  }
};

// 2. Get all Halls
exports.getAllHalls = async (req, res) => {
  try {
    const eventType = String(req.query.eventType || '').toLowerCase().trim();
    const isOrganizer = req.user?.role === 'organizer';

    const filters = [];
    if (!isOrganizer) {
      filters.push({ approvalStatus: 'approved' });
    }

    if (eventType) {
      const keywords = EVENT_KEYWORDS[eventType] || [eventType];
      filters.push({
        [Op.or]: keywords.flatMap((word) => [
          { name: { [Op.like]: `%${word}%` } },
          { description: { [Op.like]: `%${word}%` } },
          { location: { [Op.like]: `%${word}%` } },
        ]),
      });
    }

    const where = filters.length ? { [Op.and]: filters } : undefined;

    if (isPaginated(req.query)) {
      const { page, limit, offset } = getPagination(req.query);
      const result = await Hall.findAndCountAll({ where, order: [['id', 'DESC']], limit, offset });
      return res.json(buildPageResponse({ rows: result.rows, count: result.count, page, limit }));
    }

    const halls = await Hall.findAll({ where, order: [['id', 'DESC']] });
    res.json(halls);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching halls', error: error.message });
  }
};
