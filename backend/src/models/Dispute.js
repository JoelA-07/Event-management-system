const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Dispute = sequelize.define('Dispute', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  bookingType: { type: DataTypes.ENUM('hall', 'vendor'), allowNull: true },
  bookingId: { type: DataTypes.INTEGER, allowNull: true },
  paymentId: { type: DataTypes.INTEGER, allowNull: true },
  openedBy: { type: DataTypes.INTEGER, allowNull: false },
  reason: { type: DataTypes.STRING, allowNull: false },
  details: { type: DataTypes.TEXT, allowNull: true },
  status: {
    type: DataTypes.ENUM('open', 'in_review', 'resolved', 'rejected'),
    allowNull: false,
    defaultValue: 'open',
  },
  resolvedBy: { type: DataTypes.INTEGER, allowNull: true },
  resolvedAt: { type: DataTypes.DATE, allowNull: true },
  resolutionNotes: { type: DataTypes.TEXT, allowNull: true },
});

module.exports = Dispute;
