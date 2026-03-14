const jwt = require('jsonwebtoken');
const { JWT_SECRET, JWT_ISSUER, JWT_AUDIENCE } = require('../config/env');

function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!token) {
    return res.status(401).json({ message: 'Missing auth token' });
  }

  try {
    if (!JWT_SECRET) {
      return res.status(500).json({ message: 'Server auth misconfiguration' });
    }
    const verifyOptions = { algorithms: ['HS256'] };
    if (JWT_ISSUER) verifyOptions.issuer = JWT_ISSUER;
    if (JWT_AUDIENCE) verifyOptions.audience = JWT_AUDIENCE;
    const decoded = jwt.verify(token, JWT_SECRET, verifyOptions);
    req.user = decoded;
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

function requireRole(roles) {
  const allowed = Array.isArray(roles) ? roles : [roles];
  return (req, res, next) => {
    const role = req.user?.role;
    if (!role || !allowed.includes(role)) {
      return res.status(403).json({ message: 'Access denied for this role' });
    }
    return next();
  };
}

module.exports = {
  verifyToken,
  requireRole,
};
