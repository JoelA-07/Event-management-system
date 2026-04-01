const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Review = sequelize.define('Review', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  hallId: { type: DataTypes.INTEGER, allowNull: true },
  serviceId: { type: DataTypes.INTEGER, allowNull: true },
  rating: { type: DataTypes.INTEGER, allowNull: false }, // 1-5
  comment: { type: DataTypes.TEXT, allowNull: true },
  status: {
    type: DataTypes.ENUM('approved', 'pending', 'rejected'),
    allowNull: false,
    defaultValue: 'approved',
  },
  reportCount: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
  moderatedBy: { type: DataTypes.INTEGER, allowNull: true },
  moderatedAt: { type: DataTypes.DATE, allowNull: true },
}, {
  indexes: [
    { fields: ['hallId'] },
    { fields: ['serviceId'] },
    { fields: ['userId'] },
    { fields: ['status'] },
  ],
});

module.exports = Review;
