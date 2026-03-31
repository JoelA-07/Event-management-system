const { getFirebaseAdmin } = require('../config/firebaseAdmin');
const User = require('../models/User');
const UserSettings = require('../models/UserSettings');

const SETTINGS_DEFAULTS = {
  bookingAlerts: true,
  paymentAlerts: true,
  promoAlerts: false,
  profileVisible: true,
  analyticsEnabled: true,
};

const MAX_TOKENS_PER_BATCH = 500;

function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

function normalizeData(data) {
  if (!data) return {};
  const output = {};
  Object.entries(data).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    output[key] = String(value);
  });
  return output;
}

async function getUserSettings(userId) {
  const [settings] = await UserSettings.findOrCreate({
    where: { userId },
    defaults: { userId, ...SETTINGS_DEFAULTS },
  });
  return settings;
}

async function sendToToken(token, payload) {
  if (!token) return;
  const admin = getFirebaseAdmin();
  const message = {
    token,
    notification: {
      title: payload.title || 'Notification',
      body: payload.body || '',
    },
    data: normalizeData(payload.data),
  };
  await admin.messaging().send(message);
}

async function notifyUser(userId, settingKey, payload, options = {}) {
  if (!userId) return;
  const user = await User.findByPk(userId, { attributes: ['id', 'fcmToken'] });
  if (!user || !user.fcmToken) return;

  if (!options.force && settingKey) {
    const settings = await getUserSettings(userId);
    if (settings && settings[settingKey] === false) {
      return;
    }
  }

  await sendToToken(user.fcmToken, payload);
}

async function notifyOrganizers(payload) {
  const organizers = await User.findAll({
    where: { role: 'organizer' },
    attributes: ['fcmToken'],
  });
  const tokens = organizers
    .map((o) => o.fcmToken)
    .filter((t) => typeof t === 'string' && t.length > 0);

  if (!tokens.length) return;

  const admin = getFirebaseAdmin();
  const batches = chunk(tokens, MAX_TOKENS_PER_BATCH);
  for (const batch of batches) {
    const message = {
      tokens: batch,
      notification: {
        title: payload.title || 'Notification',
        body: payload.body || '',
      },
      data: normalizeData(payload.data),
    };
    await admin.messaging().sendEachForMulticast(message);
  }
}

module.exports = {
  notifyUser,
  notifyOrganizers,
};
