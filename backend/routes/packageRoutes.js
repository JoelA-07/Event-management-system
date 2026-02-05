const express = require('express');
const router = express.Router();
const { addPackage, getAllPackages, deletePackage } = require('../controllers/packageController');

// URL: /api/packages/...
router.post('/add', addPackage);
router.get('/all', getAllPackages);
router.delete('/:id', deletePackage);

module.exports = router;