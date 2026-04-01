const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const RefreshToken = sequelize.define('RefreshToken', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: false },
  tokenHash: { type: DataTypes.STRING, allowNull: false },
  expiresAt: { type: DataTypes.DATE, allowNull: false },
  revokedAt: { type: DataTypes.DATE, allowNull: true },
  lastUsedAt: { type: DataTypes.DATE, allowNull: true },
  deviceId: { type: DataTypes.STRING, allowNull: true },
  userAgent: { type: DataTypes.STRING, allowNull: true },
  ipAddress: { type: DataTypes.STRING, allowNull: true },
}, {
  indexes: [
    { fields: ['userId'] },
    { fields: ['tokenHash'] },
    { fields: ['expiresAt'] },
  ],
});

module.exports = RefreshToken;
