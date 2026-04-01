const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const {
  createReview,
  getHallReviews,
  getServiceReviews,
  reportReview,
  getReviewReports,
  moderateReview,
  resolveReviewReport,
} = require('../controllers/reviewController');

router.use(verifyToken);
router.post('/', createReview);
router.post('/:id/report', reportReview);
router.get('/hall/:hallId', getHallReviews);
router.get('/service/:serviceId', getServiceReviews);

router.get('/reports', requireRole('organizer'), getReviewReports);
router.patch('/:id/moderate', requireRole('organizer'), moderateReview);
router.patch('/reports/:id/resolve', requireRole('organizer'), resolveReviewReport);

module.exports = router;
