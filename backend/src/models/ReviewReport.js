const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const ReviewReport = sequelize.define('ReviewReport', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  reviewId: { type: DataTypes.INTEGER, allowNull: false },
  reporterId: { type: DataTypes.INTEGER, allowNull: false },
  reason: { type: DataTypes.STRING, allowNull: false },
  details: { type: DataTypes.TEXT, allowNull: true },
  status: {
    type: DataTypes.ENUM('open', 'resolved'),
    allowNull: false,
    defaultValue: 'open',
  },
  resolvedBy: { type: DataTypes.INTEGER, allowNull: true },
  resolvedAt: { type: DataTypes.DATE, allowNull: true },
});

module.exports = ReviewReport;
