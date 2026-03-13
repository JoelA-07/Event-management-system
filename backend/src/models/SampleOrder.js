const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const SampleOrder = sequelize.define('SampleOrder', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  customerId: { type: DataTypes.INTEGER, allowNull: false },
  vendorId: { type: DataTypes.INTEGER, allowNull: false },
  menuId: { type: DataTypes.INTEGER, allowNull: false },
  tastingDate: { type: DataTypes.DATEONLY, allowNull: false },
  deliveryAddress: { type: DataTypes.TEXT, allowNull: false },
  status: { type: DataTypes.STRING, defaultValue: 'pending' } // pending, preparing, delivered
});

module.exports = SampleOrder;