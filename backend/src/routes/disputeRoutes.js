const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const {
  createDispute,
  getDisputes,
  getMyDisputes,
  resolveDispute,
  linkDisputeContext,
} = require('../controllers/disputeController');

router.use(verifyToken);

router.post('/', createDispute);
router.get('/mine', getMyDisputes);
router.get('/', requireRole('organizer'), getDisputes);
router.patch('/:id', requireRole('organizer'), resolveDispute);
router.patch('/:id/link', requireRole('organizer'), linkDisputeContext);

module.exports = router;
