const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const UserSettings = sequelize.define(
  'UserSettings',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    userId: { type: DataTypes.INTEGER, allowNull: false, unique: true },
    bookingAlerts: { type: DataTypes.BOOLEAN, defaultValue: true },
    paymentAlerts: { type: DataTypes.BOOLEAN, defaultValue: true },
    promoAlerts: { type: DataTypes.BOOLEAN, defaultValue: false },
    profileVisible: { type: DataTypes.BOOLEAN, defaultValue: true },
    analyticsEnabled: { type: DataTypes.BOOLEAN, defaultValue: true },
  },
  {
    indexes: [
      {
        unique: true,
        fields: ['userId'],
        name: 'uniq_user_settings_user',
      },
    ],
  }
);

module.exports = UserSettings;
