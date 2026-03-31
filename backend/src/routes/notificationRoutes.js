const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { sendNotification, sendToAll } = require('../controllers/notificationController');

router.post('/send', verifyToken, sendNotification);
router.post('/broadcast', verifyToken, requireRole('organizer'), sendToAll);

module.exports = router;
