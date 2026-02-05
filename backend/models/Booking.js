const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Booking = sequelize.define('Booking', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  hallId: { type: DataTypes.INTEGER, allowNull: false },
  customerId: { type: DataTypes.INTEGER, allowNull: false },
  bookingDate: { type: DataTypes.DATEONLY, allowNull: false }, // Store YYYY-MM-DD
  status: { type: DataTypes.STRING, defaultValue: 'confirmed' }, // confirmed, cancelled
});

module.exports = Booking;