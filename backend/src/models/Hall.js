const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Hall = sequelize.define('Hall', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  location: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  capacity: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  pricePerDay: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
  },
  imageUrl: {
    type: DataTypes.STRING, // For now, we'll use a placeholder URL
    defaultValue: "https://via.placeholder.com/300",
  },
  ownerId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  }
});

module.exports = Hall;