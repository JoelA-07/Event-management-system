const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Payment = sequelize.define('Payment', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  bookingType: { type: DataTypes.ENUM('hall', 'vendor'), allowNull: false },
  bookingId: { type: DataTypes.INTEGER, allowNull: false },
  customerId: { type: DataTypes.INTEGER, allowNull: false },
  vendorId: { type: DataTypes.INTEGER, allowNull: true },
  totalAmount: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
  advanceAmount: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
  paidAmount: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
  refundedAmount: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
  organizerFeePercent: { type: DataTypes.DECIMAL(5, 2), allowNull: true },
  status: {
    type: DataTypes.ENUM('pending', 'partial', 'paid', 'refunded'),
    allowNull: false,
    defaultValue: 'pending',
  },
  currency: { type: DataTypes.STRING, allowNull: false, defaultValue: 'INR' },
  receiptNumber: { type: DataTypes.STRING, allowNull: true },
  receiptIssuedAt: { type: DataTypes.DATE, allowNull: true },
});

module.exports = Payment;
