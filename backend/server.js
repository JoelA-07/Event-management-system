const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const sequelize = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const hallRoutes = require('./routes/hallRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const vendorRoutes = require('./routes/vendorRoutes');
const packageRoutes = require('./routes/packageRoutes');
const vendorBookingRoutes = require('./routes/vendorBookingRoutes');
const Hall = require('./models/Hall');
const Booking = require('./models/Booking');
const VendorBooking = require('./models/VendorBooking');
const VendorService = require('./models/VendorService');
const path = require('path');
const aiRoutes = require('./routes/aiRoutes');


dotenv.config();
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/halls', hallRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/vendors', vendorRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/vendor-bookings', vendorBookingRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/api/ai', aiRoutes);

// Test route
app.get('/', (req, res) => {
  res.send('Event Management API is Running 🚀');
});

// Sync database and start server
const PORT = process.env.PORT || 5000;

// Define Relationships
Hall.hasMany(Booking, { foreignKey: 'hallId' });
Booking.belongsTo(Hall, { foreignKey: 'hallId' });
VendorService.hasMany(VendorBooking, { foreignKey: 'serviceId' });
VendorBooking.belongsTo(VendorService, { foreignKey: 'serviceId' });

// Ensure the 'uploads' folder exists!
const fs = require('fs');
if (!fs.existsSync('./uploads')) {
    fs.mkdirSync('./uploads');
}

sequelize.sync({ alter: true }) // Updates tables without dropping data
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  })
  .catch(err => {
    console.log('Database connection failed:', err);
  });
