const express = require('express');
const cors = require('cors');
const env = require('./src/config/env');
const sequelize = require('./src/config/db');
const authRoutes = require('./src/routes/authRoutes');
const hallRoutes = require('./src/routes/hallRoutes');
const bookingRoutes = require('./src/routes/bookingRoutes');
const vendorRoutes = require('./src/routes/vendorRoutes');
const packageRoutes = require('./src/routes/packageRoutes');
const vendorBookingRoutes = require('./src/routes/vendorBookingRoutes');
const organizerRoutes = require('./src/routes/organizerRoutes');
const reviewRoutes = require('./src/routes/reviewRoutes');
const Hall = require('./src/models/Hall');
const Booking = require('./src/models/Booking');
const BookingLock = require('./src/models/BookingLock');
const VendorBooking = require('./src/models/VendorBooking');
const VendorDateLock = require('./src/models/VendorDateLock');
const VendorService = require('./src/models/VendorService');
const VendorAvailability = require('./src/models/VendorAvailability');
const User = require('./src/models/User');
const Review = require('./src/models/Review');
const path = require('path');
const aiRoutes = require('./src/routes/aiRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes');

const app = express();

// Middleware
app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    const allowList = [
      /^http:\/\/localhost:\d+$/,
      /^http:\/\/127\.0\.0\.1:\d+$/,
    ];
    const allowed = allowList.some((pattern) => pattern.test(origin));
    return callback(null, allowed);
  },
  credentials: true,
}));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/halls', hallRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/vendors', vendorRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/vendor-bookings', vendorBookingRoutes);
app.use('/api/organizer', organizerRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/api/ai', aiRoutes);
app.use('/api/notifications', notificationRoutes);

// Test route
app.get('/', (req, res) => {
  res.send('Event Management API is Running 🚀');
});

// Sync database and start server
const PORT = env.PORT;

// Define Relationships
Hall.hasMany(Booking, { foreignKey: 'hallId' });
Booking.belongsTo(Hall, { foreignKey: 'hallId' });
VendorService.hasMany(VendorBooking, { foreignKey: 'serviceId' });
VendorBooking.belongsTo(VendorService, { foreignKey: 'serviceId' });
VendorService.hasMany(VendorAvailability, { foreignKey: 'serviceId' });
VendorAvailability.belongsTo(VendorService, { foreignKey: 'serviceId' });
User.hasMany(Review, { foreignKey: 'userId' });
Review.belongsTo(User, { foreignKey: 'userId' });
Hall.hasMany(Review, { foreignKey: 'hallId' });
Review.belongsTo(Hall, { foreignKey: 'hallId' });
VendorService.hasMany(Review, { foreignKey: 'serviceId' });
Review.belongsTo(VendorService, { foreignKey: 'serviceId' });

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
