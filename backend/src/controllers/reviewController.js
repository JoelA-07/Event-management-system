const Review = require('../models/Review');
const ReviewReport = require('../models/ReviewReport');
const User = require('../models/User');

exports.createReview = async (req, res) => {
  try {
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    const { hallId, serviceId, rating, comment } = req.body;
    if ((!hallId && !serviceId) || (hallId && serviceId)) {
      return res.status(400).json({ message: 'Provide either hallId or serviceId' });
    }
    const numericRating = Number(rating);
    if (!numericRating || numericRating < 1 || numericRating > 5) {
      return res.status(400).json({ message: 'Rating must be between 1 and 5' });
    }

    const review = await Review.create({
      userId: req.user.id,
      hallId: hallId || null,
      serviceId: serviceId || null,
      rating: numericRating,
      comment: comment?.toString() || '',
      status: 'pending',
    });
    res.status(201).json(review);
  } catch (error) {
    res.status(500).json({ message: 'Error creating review', error: error.message });
  }
};

exports.getHallReviews = async (req, res) => {
  try {
    const { hallId } = req.params;
    const isOrganizer = req.user?.role === 'organizer';
    const where = { hallId, ...(isOrganizer ? {} : { status: 'approved' }) };
    const reviews = await Review.findAll({
      where,
      include: [{ model: User, attributes: ['id', 'name'] }],
      order: [['createdAt', 'DESC']],
    });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching reviews', error: error.message });
  }
};

exports.getServiceReviews = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const isOrganizer = req.user?.role === 'organizer';
    const where = { serviceId, ...(isOrganizer ? {} : { status: 'approved' }) };
    const reviews = await Review.findAll({
      where,
      include: [{ model: User, attributes: ['id', 'name'] }],
      order: [['createdAt', 'DESC']],
    });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching reviews', error: error.message });
  }
};

exports.reportReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { reason, details } = req.body;
    if (!req.user) return res.status(401).json({ message: 'Unauthorized' });
    if (!reason) return res.status(400).json({ message: 'reason is required' });

    const review = await Review.findByPk(id);
    if (!review) return res.status(404).json({ message: 'Review not found' });

    await ReviewReport.create({
      reviewId: review.id,
      reporterId: req.user.id,
      reason,
      details,
      status: 'open',
    });

    review.reportCount = Number(review.reportCount || 0) + 1;
    if (review.reportCount >= 3 && review.status === 'approved') {
      review.status = 'pending';
    }
    await review.save();

    res.json({ message: 'Review reported', reviewId: review.id });
  } catch (error) {
    res.status(500).json({ message: 'Error reporting review', error: error.message });
  }
};

exports.getReviewReports = async (req, res) => {
  try {
    const status = req.query.status || 'open';
    const reports = await ReviewReport.findAll({
      where: { status },
      include: [
        {
          model: Review,
          include: [{ model: User, attributes: ['id', 'name'] }],
        },
      ],
      order: [['id', 'DESC']],
    });
    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching reports', error: error.message });
  }
};

exports.moderateReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    if (!status || !['approved', 'rejected', 'pending'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const review = await Review.findByPk(id);
    if (!review) return res.status(404).json({ message: 'Review not found' });

    review.status = status;
    review.moderatedBy = req.user?.id;
    review.moderatedAt = new Date();
    if (notes) review.comment = review.comment || notes;
    await review.save();

    res.json({ message: 'Review moderated', review });
  } catch (error) {
    res.status(500).json({ message: 'Error moderating review', error: error.message });
  }
};

exports.resolveReviewReport = async (req, res) => {
  try {
    const { id } = req.params;
    const report = await ReviewReport.findByPk(id);
    if (!report) return res.status(404).json({ message: 'Report not found' });

    report.status = 'resolved';
    report.resolvedBy = req.user?.id;
    report.resolvedAt = new Date();
    await report.save();

    res.json({ message: 'Report resolved', report });
  } catch (error) {
    res.status(500).json({ message: 'Error resolving report', error: error.message });
  }
};
