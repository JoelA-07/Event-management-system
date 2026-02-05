const express = require('express');
const router = express.Router();
const { getChatSuggestion } = require('../controllers/aiController');

// URL: /api/ai/chat
// This route will handle the AI Chatbot messages
router.post('/chat', getChatSuggestion);

// Future Route: /api/ai/recommend-decor
// router.post('/recommend-decor', getDecorRecommendations);

module.exports = router;