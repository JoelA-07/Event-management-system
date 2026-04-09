const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const PaymentTransaction = sequelize.define('PaymentTransaction', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  paymentId: { type: DataTypes.INTEGER, allowNull: false },
  type: { type: DataTypes.ENUM('advance', 'balance', 'custom', 'refund'), allowNull: false },
  amount: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  method: { type: DataTypes.ENUM('online', 'cash', 'manual'), allowNull: false },
  status: { type: DataTypes.ENUM('pending', 'paid', 'failed'), allowNull: false, defaultValue: 'pending' },
  razorpayPaymentId: { type: DataTypes.STRING, allowNull: true },
  razorpayOrderId: { type: DataTypes.STRING, allowNull: true },
  razorpayPaymentLinkId: { type: DataTypes.STRING, allowNull: true },
  razorpayPaymentLinkReferenceId: { type: DataTypes.STRING, allowNull: true },
  paidAt: { type: DataTypes.DATE, allowNull: true },
  createdBy: { type: DataTypes.INTEGER, allowNull: true },
  notes: { type: DataTypes.STRING, allowNull: true },
});

module.exports = PaymentTransaction;
