const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const {
  getOrganizerOverview,
  getOrganizerAnalytics,
  listPendingApprovals,
  approveHall,
  approveVendorService,
  getPayoutDashboard,
  getBookingDashboard,
} = require('../controllers/organizerController');

router.use(verifyToken);

router.get('/overview', requireRole('organizer'), getOrganizerOverview);
router.get('/analytics', requireRole('organizer'), getOrganizerAnalytics);
router.get('/approvals', requireRole('organizer'), listPendingApprovals);
router.patch('/approvals/halls/:id', requireRole('organizer'), approveHall);
router.patch('/approvals/services/:id', requireRole('organizer'), approveVendorService);
router.get('/payouts', requireRole('organizer'), getPayoutDashboard);
router.get('/bookings', requireRole('organizer'), getBookingDashboard);

module.exports = router;
