const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Package = sequelize.define('Package', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  organizerId: { type: DataTypes.INTEGER, allowNull: false },
  title: { type: DataTypes.STRING, allowNull: false },
  description: { type: DataTypes.TEXT },
  totalPrice: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  discountedPrice: { type: DataTypes.DECIMAL(10, 2) },
  // Store the IDs of the combined services as a JSON array
  serviceIds: { type: DataTypes.JSON, allowNull: false }, 
  imageUrl: { type: DataTypes.STRING, defaultValue: "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=500" }
});

module.exports = Package;