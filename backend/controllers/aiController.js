const { OpenAI } = require('openai');
require('dotenv').config();

// Initialize OpenAI with your Secret Key from .env
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY, 
});

exports.getChatSuggestion = async (req, res) => {
  try {
    const { message } = req.body;

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo", // You can use gpt-4 for better results
      messages: [
        { 
          role: "system", 
          content: "You are the Jireh Events's Assistant. You help users find halls, photographers, and caterers. Suggest packages and be very polite." 
        },
        { role: "user", content: message },
      ],
    });

    res.json({ reply: completion.choices[0].message.content });
  } catch (error) {
    console.error("AI Error:", error);
    res.status(500).json({ message: "The AI is currently resting. Try again later." });
  }
};