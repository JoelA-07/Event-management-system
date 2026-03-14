const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VendorAvailability = sequelize.define('VendorAvailability', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  vendorId: { type: DataTypes.INTEGER, allowNull: false },
  serviceId: { type: DataTypes.INTEGER, allowNull: false },
  date: { type: DataTypes.DATEONLY, allowNull: false },
  slotType: {
    type: DataTypes.ENUM('hourly', 'half_day', 'full_day'),
    allowNull: false,
    defaultValue: 'full_day',
  },
  startTime: { type: DataTypes.TIME, allowNull: true },
  endTime: { type: DataTypes.TIME, allowNull: true },
  reason: { type: DataTypes.STRING },
});

module.exports = VendorAvailability;
