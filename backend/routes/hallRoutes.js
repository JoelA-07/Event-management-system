const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { verifyToken, requireRole } = require('../middleware/auth');
const { addHall, getAllHalls } = require('../controllers/hallController');

router.use(verifyToken);

router.post('/add', requireRole(['hall_owner', 'organizer']), upload, addHall);
router.get('/all', getAllHalls);

module.exports = router;
