const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const BookingLock = sequelize.define(
  'BookingLock',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    hallId: { type: DataTypes.INTEGER, allowNull: false },
    bookingDate: { type: DataTypes.DATEONLY, allowNull: false },
  },
  {
    indexes: [
      {
        unique: true,
        fields: ['hallId', 'bookingDate'],
        name: 'uniq_hall_date_lock',
      },
    ],
  }
);

module.exports = BookingLock;
