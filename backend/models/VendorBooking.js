const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VendorBooking = sequelize.define('VendorBooking', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  vendorId: { type: DataTypes.INTEGER, allowNull: false },
  serviceId: { type: DataTypes.INTEGER, allowNull: false },
  customerId: { type: DataTypes.INTEGER, allowNull: false },
  bookingDate: { type: DataTypes.DATEONLY, allowNull: false },
  notes: { type: DataTypes.TEXT },
  status: { type: DataTypes.STRING, defaultValue: 'pending' }, // pending, confirmed, cancelled
});

module.exports = VendorBooking;
