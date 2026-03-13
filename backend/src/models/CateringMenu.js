const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const CateringMenu = sequelize.define('CateringMenu', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  vendorId: { type: DataTypes.INTEGER, allowNull: false },
  packageName: { type: DataTypes.STRING, allowNull: false }, // e.g., "Silver South Indian"
  cuisineType: { type: DataTypes.STRING }, // Veg, Non-Veg, Multi-cuisine
  pricePerPlate: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  menuItems: { type: DataTypes.TEXT }, // A string/list of items like "Idli, Sambar, Vada"
  isSampleAvailable: { type: DataTypes.BOOLEAN, defaultValue: true },
  samplePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 500.00 }, // Fee for tasting
  imageUrl: { type: DataTypes.STRING }
});

module.exports = CateringMenu;