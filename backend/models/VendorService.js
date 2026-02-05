const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VendorService = sequelize.define('VendorService', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  vendorId: { type: DataTypes.INTEGER, allowNull: false }, // Links to User (Role: Photographer/Caterer)
  name: { type: DataTypes.STRING, allowNull: false },
  category: { 
    type: DataTypes.ENUM('photographer', 'caterer', 'designer'), 
    allowNull: false 
  },
  price: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  description: { type: DataTypes.TEXT },
  imageUrl: { type: DataTypes.STRING, defaultValue: "https://via.placeholder.com/300" },
  menuOrPortfolio: { type: DataTypes.JSON }, // Stores array of images or menu items
});

module.exports = VendorService;