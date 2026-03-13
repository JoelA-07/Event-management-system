const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Booking = sequelize.define(
  'Booking',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    hallId: { type: DataTypes.INTEGER, allowNull: false },
    customerId: { type: DataTypes.INTEGER, allowNull: false },
    bookingDate: { type: DataTypes.DATEONLY, allowNull: false }, // Store YYYY-MM-DD
    slotType: {
      type: DataTypes.ENUM('hourly', 'half_day', 'full_day'),
      allowNull: false,
      defaultValue: 'full_day',
    },
    startTime: { type: DataTypes.TIME, allowNull: true }, // For hourly/half-day
    endTime: { type: DataTypes.TIME, allowNull: true }, // For hourly/half-day
    status: { type: DataTypes.STRING, defaultValue: 'confirmed' }, // confirmed, cancelled
  },
  {
    indexes: [
      {
        unique: true,
        fields: ['hallId', 'bookingDate', 'startTime', 'endTime'],
        name: 'uniq_hall_date_time',
      },
    ],
  },
);

module.exports = Booking;
