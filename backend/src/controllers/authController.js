const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const { JWT_SECRET, JWT_EXPIRES_IN, JWT_ISSUER, JWT_AUDIENCE, REFRESH_TOKEN_EXPIRES_IN_DAYS, GOOGLE_WEB_CLIENT_ID, GOOGLE_WEB_CLIENT_SECRET } = require('../config/env');
const { getFirebaseAdmin } = require('../config/firebaseAdmin');

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function getSignOptions() {
  const signOptions = { expiresIn: JWT_EXPIRES_IN };
  if (JWT_ISSUER) signOptions.issuer = JWT_ISSUER;
  if (JWT_AUDIENCE) signOptions.audience = JWT_AUDIENCE;
  return signOptions;
}

function getGoogleClient() {
  if (!GOOGLE_WEB_CLIENT_ID || !GOOGLE_WEB_CLIENT_SECRET) {
    throw new Error('Google OAuth is not configured');
  }
  return new OAuth2Client(GOOGLE_WEB_CLIENT_ID, GOOGLE_WEB_CLIENT_SECRET, 'postmessage');
}

async function findOrCreateGoogleUser(profile) {
  const { email, name } = profile;
  let user = await User.findOne({ where: { email } });
  if (user) {
    return user;
  }

  const salt = await bcrypt.genSalt(10);
  const randomPassword = crypto.randomBytes(32).toString('hex');
  const hashedPassword = await bcrypt.hash(randomPassword, salt);

  user = await User.create({
    name: name || email?.split('@')[0] || 'Google User',
    email,
    password: hashedPassword,
    role: 'customer',
  });

  return user;
}

async function findOrCreateFirebaseUser(profile) {
  const { email, name } = profile;
  let user = await User.findOne({ where: { email } });
  if (user) {
    return user;
  }

  const salt = await bcrypt.genSalt(10);
  const randomPassword = crypto.randomBytes(32).toString('hex');
  const hashedPassword = await bcrypt.hash(randomPassword, salt);

  user = await User.create({
    name: name || email?.split('@')[0] || 'Google User',
    email,
    password: hashedPassword,
    role: 'customer',
  });

  return user;
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

exports.googleLogin = async (req, res) => {
  try {
    const { serverAuthCode, idToken } = req.body;
    if (!serverAuthCode) {
      return res.status(400).json({ message: 'Missing serverAuthCode' });
    }

    const client = getGoogleClient();
    const { tokens } = await client.getToken(serverAuthCode);
    const tokenToVerify = tokens?.id_token || idToken;
    if (!tokenToVerify) {
      return res.status(400).json({ message: 'Missing id token' });
    }

    const ticket = await client.verifyIdToken({
      idToken: tokenToVerify,
      audience: GOOGLE_WEB_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    if (!payload?.email) {
      return res.status(400).json({ message: 'Google account email not found' });
    }

    const user = await findOrCreateGoogleUser({
      email: payload.email,
      name: payload.name,
    });

    const { accessToken, refreshToken } = await issueTokens(user);
    res.json({
      token: accessToken,
      refreshToken,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ message: 'Google login failed', error: error.message });
  }
};

exports.firebaseLogin = async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: 'Missing Firebase ID token' });
    }

    const admin = getFirebaseAdmin();
    const decoded = await admin.auth().verifyIdToken(idToken);
    const email = decoded?.email;
    const name = decoded?.name || decoded?.displayName;

    if (!email) {
      return res.status(400).json({ message: 'Firebase account email not found' });
    }

    const user = await findOrCreateFirebaseUser({ email, name });
    const { accessToken, refreshToken } = await issueTokens(user);

    res.json({
      token: accessToken,
      refreshToken,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  } catch (error) {
    const message = error?.message || 'Unknown error';

    if (message.includes('Firebase Admin not configured')) {
      return res.status(500).json({
        message: 'Firebase Admin not configured',
        error: message,
        hint: 'Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH in backend/.env',
      });
    }

    if (message.toLowerCase().includes('id token') || message.toLowerCase().includes('token')) {
      return res.status(401).json({
        message: 'Invalid Firebase ID token',
        error: message,
      });
    }

    res.status(500).json({ message: 'Firebase login failed', error: message });
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

exports.updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ message: 'Missing FCM token' });
    }

    const user = await User.findByPk(req.user?.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.fcmToken = fcmToken;
    await user.save();

    return res.json({ message: 'FCM token saved' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to save FCM token' });
  }
};
