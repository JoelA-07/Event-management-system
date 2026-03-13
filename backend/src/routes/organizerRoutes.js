const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { getOrganizerOverview, getOrganizerAnalytics } = require('../controllers/organizerController');

router.use(verifyToken);
router.get('/overview', requireRole('organizer'), getOrganizerOverview);
router.get('/analytics', requireRole('organizer'), getOrganizerAnalytics);

module.exports = router;
