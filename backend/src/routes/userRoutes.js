const express = require('express');
const { verifyToken, requireRole } = require('../middleware/auth');
const {
  getMe,
  updateMe,
  changePassword,
  getSettings,
  updateSettings,
  searchUsers,
} = require('../controllers/userController');

const router = express.Router();

router.get('/me', verifyToken, getMe);
router.patch('/me', verifyToken, updateMe);
router.post('/me/change-password', verifyToken, changePassword);
router.get('/me/settings', verifyToken, getSettings);
router.patch('/me/settings', verifyToken, updateSettings);
router.get('/search', verifyToken, requireRole('organizer'), searchUsers);

module.exports = router;
