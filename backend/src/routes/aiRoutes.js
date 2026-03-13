const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { getChatSuggestion } = require('../controllers/aiController');

// URL: /api/ai/chat
// This route will handle the AI Chatbot messages
router.post('/chat', verifyToken, getChatSuggestion);

// Future Route: /api/ai/recommend-decor
// router.post('/recommend-decor', getDecorRecommendations);

module.exports = router;
