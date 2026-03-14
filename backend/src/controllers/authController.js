const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { JWT_SECRET, JWT_EXPIRES_IN, JWT_ISSUER, JWT_AUDIENCE, REFRESH_TOKEN_EXPIRES_IN_DAYS } = require('../config/env');

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function getSignOptions() {
  const signOptions = { expiresIn: JWT_EXPIRES_IN };
  if (JWT_ISSUER) signOptions.issuer = JWT_ISSUER;
  if (JWT_AUDIENCE) signOptions.audience = JWT_AUDIENCE;
  return signOptions;
}

async function issueTokens(user) {
  if (!JWT_SECRET) {
    throw new Error('Server auth misconfiguration');
  }
  const accessToken = jwt.sign(
    { id: user.id, role: user.role },
    JWT_SECRET,
    getSignOptions(),
  );

  const refreshToken = crypto.randomBytes(64).toString('hex');
  const refreshTokenHash = hashToken(refreshToken);
  const refreshTokenExpiresAt = new Date(
    Date.now() + REFRESH_TOKEN_EXPIRES_IN_DAYS * 24 * 60 * 60 * 1000,
  );

  user.refreshTokenHash = refreshTokenHash;
  user.refreshTokenExpiresAt = refreshTokenExpiresAt;
  await user.save();

  return { accessToken, refreshToken };
}

// Register
exports.register = async (req, res) => {
  try {
    const { name, email, password, phone, role } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      phone,
      role: role || 'customer', 
    });

    res.status(201).json({
      message: 'User registered successfully',
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Create JWT token
    const { accessToken, refreshToken } = await issueTokens(user);

    res.json({
      token: accessToken,
      refreshToken,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

exports.refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ message: 'Missing refresh token' });
    }

    const refreshTokenHash = hashToken(refreshToken);
    const user = await User.findOne({ where: { refreshTokenHash } });
    if (!user || !user.refreshTokenExpiresAt || user.refreshTokenExpiresAt < new Date()) {
      return res.status(401).json({ message: 'Invalid or expired refresh token' });
    }

    const { accessToken, refreshToken: newRefreshToken } = await issueTokens(user);

    res.json({
      token: accessToken,
      refreshToken: newRefreshToken,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ message: 'Missing refresh token' });
    }

    const refreshTokenHash = hashToken(refreshToken);
    const user = await User.findOne({ where: { refreshTokenHash } });
    if (user) {
      user.refreshTokenHash = null;
      user.refreshTokenExpiresAt = null;
      await user.save();
    }
    return res.json({ message: 'Logged out' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};
