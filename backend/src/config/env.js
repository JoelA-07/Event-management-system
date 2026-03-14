const dotenv = require('dotenv');

dotenv.config();

const required = ['DB_NAME', 'DB_USER', 'DB_PASSWORD', 'DB_HOST', 'JWT_SECRET'];
const missing = required.filter((key) => !process.env[key]);

if (missing.length > 0) {
  console.warn(`[env] Missing required variables: ${missing.join(', ')}`);
}

module.exports = {
  PORT: process.env.PORT || 5000,
  DB_NAME: process.env.DB_NAME,
  DB_USER: process.env.DB_USER,
  DB_PASSWORD: process.env.DB_PASSWORD,
  DB_HOST: process.env.DB_HOST,
  JWT_SECRET: process.env.JWT_SECRET,
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
  JWT_ISSUER: process.env.JWT_ISSUER || 'jireh-events',
  JWT_AUDIENCE: process.env.JWT_AUDIENCE || 'jireh-events-app',
  REFRESH_TOKEN_EXPIRES_IN_DAYS: Number(process.env.REFRESH_TOKEN_EXPIRES_IN_DAYS || 30),
  OPENAI_API_KEY: process.env.OPENAI_API_KEY,
};
