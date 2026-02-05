const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { addHall, getAllHalls } = require('../controllers/hallController');

// Add 'upload' before 'addHall'
router.post('/add', upload, addHall);
router.post('/add', addHall);
router.get('/all', getAllHalls);

module.exports = router;