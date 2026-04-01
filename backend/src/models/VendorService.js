const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VendorService = sequelize.define('VendorService', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  vendorId: { type: DataTypes.INTEGER, allowNull: false }, // Links to User (Role: Photographer/Caterer)
  name: { type: DataTypes.STRING, allowNull: false },
  category: { 
    type: DataTypes.ENUM('photographer', 'caterer', 'designer', 'decorator', 'mehendi'), 
    allowNull: false 
  },
  price: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  description: { type: DataTypes.TEXT },
  imageUrl: { type: DataTypes.STRING, defaultValue: "https://via.placeholder.com/300" },
  menuOrPortfolio: { type: DataTypes.JSON }, // Stores array of images or menu items
  unitPrice: { type: DataTypes.DECIMAL(10, 2) }, // Optional: per-copy pricing for designers
  approvalStatus: {
    type: DataTypes.ENUM('pending', 'approved', 'rejected'),
    allowNull: false,
    defaultValue: 'pending',
  },
  approvedBy: { type: DataTypes.INTEGER, allowNull: true },
  approvedAt: { type: DataTypes.DATE, allowNull: true },
  rejectionReason: { type: DataTypes.STRING, allowNull: true },
});

module.exports = VendorService;
