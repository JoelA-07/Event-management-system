const Hall = require('../models/Hall');

// 1. Add a new Hall
exports.addHall = async (req, res) => {
  try {
    const { name, location, capacity, pricePerDay, description, ownerId } = req.body;
    
    // Get the filename from multer
    const imageUrl = req.file ? `/uploads/${req.file.filename}` : "/uploads/default.jpg";

    const hall = await Hall.create({ 
      name, location, capacity, pricePerDay, description, ownerId, 
      imageUrl: imageUrl // Save path to DB
    });
    res.status(201).json(hall);
  } catch (error) {
    res.status(500).json({ message: "Error adding hall", error: error.message });
  }
};

// 2. Get all Halls
exports.getAllHalls = async (req, res) => {
  try {
    const halls = await Hall.findAll();
    res.json(halls);
  } catch (error) {
    res.status(500).json({ message: "Error fetching halls" });
  }
};