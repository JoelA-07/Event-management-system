const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { createReview, getHallReviews, getServiceReviews } = require('../controllers/reviewController');

router.use(verifyToken);
router.post('/', createReview);
router.get('/hall/:hallId', getHallReviews);
router.get('/service/:serviceId', getServiceReviews);

module.exports = router;
