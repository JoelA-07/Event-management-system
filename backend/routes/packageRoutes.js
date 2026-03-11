const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { addPackage, getAllPackages, deletePackage } = require('../controllers/packageController');

// URL: /api/packages/...
router.use(verifyToken);

router.post('/add', requireRole('organizer'), addPackage);
router.get('/all', getAllPackages);
router.delete('/:id', requireRole('organizer'), deletePackage);

module.exports = router;
