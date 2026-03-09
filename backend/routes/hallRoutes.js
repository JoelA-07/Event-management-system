const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const { addHall, getAllHalls } = require('../controllers/hallController');

router.post('/add', upload, addHall);
router.get('/all', getAllHalls);

module.exports = router;
