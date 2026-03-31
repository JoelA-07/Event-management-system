const bcrypt = require('bcryptjs');
const User = require('../models/User');
const UserSettings = require('../models/UserSettings');

const SETTINGS_DEFAULTS = {
  bookingAlerts: true,
  paymentAlerts: true,
  promoAlerts: false,
  profileVisible: true,
  analyticsEnabled: true,
};

function sanitizeText(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length ? trimmed : null;
}

exports.getMe = async (req, res) => {
  try {
    const user = await User.findByPk(req.user?.id, {
      attributes: ['id', 'name', 'email', 'phone', 'role'],
    });
    if (!user) return res.status(404).json({ message: 'User not found' });
    return res.json(user);
  } catch (error) {
    return res.status(500).json({ message: 'Failed to load profile' });
  }
};

exports.updateMe = async (req, res) => {
  try {
    const user = await User.findByPk(req.user?.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const name = sanitizeText(req.body.name);
    const email = sanitizeText(req.body.email);
    const phone = sanitizeText(req.body.phone);

    const hasPhone = Object.prototype.hasOwnProperty.call(req.body, 'phone');

    if (email && email !== user.email) {
      const existing = await User.findOne({ where: { email } });
      if (existing) {
        return res.status(400).json({ message: 'Email already in use' });
      }
      user.email = email;
    }

    if (name) user.name = name;
    if (hasPhone) user.phone = phone;

    await user.save();

    return res.json({
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update profile' });
  }
};

exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Current and new password are required' });
    }
    if (newPassword.length < 8) {
      return res.status(400).json({ message: 'New password must be at least 8 characters' });
    }

    const user = await User.findByPk(req.user?.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const match = await bcrypt.compare(currentPassword, user.password);
    if (!match) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    await user.save();

    return res.json({ message: 'Password updated successfully' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update password' });
  }
};

exports.getSettings = async (req, res) => {
  try {
    const [settings] = await UserSettings.findOrCreate({
      where: { userId: req.user?.id },
      defaults: { userId: req.user?.id, ...SETTINGS_DEFAULTS },
    });
    return res.json(settings);
  } catch (error) {
    return res.status(500).json({ message: 'Failed to load settings' });
  }
};

exports.updateSettings = async (req, res) => {
  try {
    const updates = {};
    const allowed = Object.keys(SETTINGS_DEFAULTS);
    allowed.forEach((field) => {
      if (typeof req.body[field] === 'boolean') {
        updates[field] = req.body[field];
      }
    });

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ message: 'No valid settings provided' });
    }

    const [settings] = await UserSettings.findOrCreate({
      where: { userId: req.user?.id },
      defaults: { userId: req.user?.id, ...SETTINGS_DEFAULTS },
    });

    await settings.update(updates);
    return res.json(settings);
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update settings' });
  }
};
