const { getFirebaseAdmin } = require('../config/firebaseAdmin');
const User = require('../models/User');

const ALL_TOPIC = 'all';
const MAX_TOKENS_PER_BATCH = 500;

function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

exports.sendNotification = async (req, res) => {
  try {
    const { userId, email, title, body, data } = req.body;
    const targetUserId = userId || req.user?.id;

    let resolvedUserId = targetUserId;
    if (!resolvedUserId && email) {
      const userByEmail = await User.findOne({ where: { email } });
      if (!userByEmail) {
        return res.status(404).json({ message: 'User not found for email' });
      }
      resolvedUserId = userByEmail.id;
    }

    if (!resolvedUserId) {
      return res.status(400).json({ message: 'Missing target user' });
    }

    const isOrganizer = req.user?.role === 'organizer';
    if (req.user?.id && String(resolvedUserId) !== String(req.user.id) && !isOrganizer) {
      return res.status(403).json({ message: 'Cannot send notifications to other users' });
    }

    const user = await User.findByPk(resolvedUserId);
    if (!user || !user.fcmToken) {
      return res.status(404).json({ message: 'FCM token not found for user' });
    }

    const admin = getFirebaseAdmin();
    const message = {
      token: user.fcmToken,
      notification: {
        title: title || 'Notification',
        body: body || '',
      },
      data: data || {},
    };

    const response = await admin.messaging().send(message);
    return res.json({ message: 'Notification sent', id: response });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to send notification', error: error.message });
  }
};

exports.sendToAll = async (req, res) => {
  try {
    const { title, body, data } = req.body;

    const admin = getFirebaseAdmin();

    const topicMessage = {
      topic: ALL_TOPIC,
      notification: {
        title: title || 'Notification',
        body: body || '',
      },
      data: data || {},
    };

    const topicResponse = await admin.messaging().send(topicMessage);

    const webUsers = await User.findAll({
      where: { fcmPlatform: 'web' },
      attributes: ['fcmToken'],
    });

    const webTokens = webUsers
      .map((u) => u.fcmToken)
      .filter((t) => typeof t === 'string' && t.length > 0);

    let webSuccess = 0;
    let webFailure = 0;

    const batches = chunk(webTokens, MAX_TOKENS_PER_BATCH);
    for (const batch of batches) {
      const multicastMessage = {
        tokens: batch,
        notification: {
          title: title || 'Notification',
          body: body || '',
        },
        data: data || {},
      };

      const response = await admin.messaging().sendEachForMulticast(multicastMessage);
      webSuccess += response.successCount || 0;
      webFailure += response.failureCount || 0;
    }

    return res.json({
      message: 'Broadcast sent',
      topicId: topicResponse,
      web: { success: webSuccess, failure: webFailure, tokens: webTokens.length },
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to send broadcast', error: error.message });
  }
};
