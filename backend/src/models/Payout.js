const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Payout = sequelize.define('Payout', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  paymentId: { type: DataTypes.INTEGER, allowNull: false },
  vendorId: { type: DataTypes.INTEGER, allowNull: false },
  amount: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  organizerFeePercent: { type: DataTypes.DECIMAL(5, 2), allowNull: true },
  status: { type: DataTypes.ENUM('pending', 'paid'), allowNull: false, defaultValue: 'pending' },
  paidAt: { type: DataTypes.DATE, allowNull: true },
  notes: { type: DataTypes.STRING, allowNull: true },
});

module.exports = Payout;
