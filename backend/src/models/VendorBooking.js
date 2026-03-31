const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VendorBooking = sequelize.define(
  'VendorBooking',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    vendorId: { type: DataTypes.INTEGER, allowNull: false },
    serviceId: { type: DataTypes.INTEGER, allowNull: false },
    customerId: { type: DataTypes.INTEGER, allowNull: false },
    bookingDate: { type: DataTypes.DATEONLY, allowNull: false },
    slotType: {
      type: DataTypes.ENUM('hourly', 'half_day', 'full_day'),
      allowNull: false,
      defaultValue: 'full_day',
    },
    startTime: { type: DataTypes.TIME, allowNull: true },
    endTime: { type: DataTypes.TIME, allowNull: true },
    notes: { type: DataTypes.TEXT },
    status: { type: DataTypes.STRING, defaultValue: 'pending' }, // pending, confirmed, completed, cancelled
  },
  {
    indexes: [
      {
        unique: true,
        fields: ['vendorId', 'serviceId', 'bookingDate', 'startTime', 'endTime'],
        name: 'uniq_vendor_service_date_time',
      },
    ],
  }
);

module.exports = VendorBooking;
