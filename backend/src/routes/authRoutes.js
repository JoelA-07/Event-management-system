const express = require('express');
const router = express.Router();
const { register, login, refresh, logout, googleLogin, firebaseLogin, updateFcmToken } = require('../controllers/authController.js');
const { verifyToken } = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/firebase', firebaseLogin);
router.post('/refresh', refresh);
router.post('/logout', logout);
router.post('/fcm-token', verifyToken, updateFcmToken);

module.exports = router;
