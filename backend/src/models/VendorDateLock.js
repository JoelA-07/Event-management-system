const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const VendorDateLock = sequelize.define(
  'VendorDateLock',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    vendorId: { type: DataTypes.INTEGER, allowNull: false },
    serviceId: { type: DataTypes.INTEGER, allowNull: false },
    date: { type: DataTypes.DATEONLY, allowNull: false },
  },
  {
    indexes: [
      {
        unique: true,
        fields: ['vendorId', 'serviceId', 'date'],
        name: 'uniq_vendor_service_date_lock',
      },
    ],
  }
);

module.exports = VendorDateLock;
