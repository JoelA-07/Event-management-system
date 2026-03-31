const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT_PATH } = require('./env');

function loadServiceAccount() {
  if (FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(FIREBASE_SERVICE_ACCOUNT_JSON);
  }

  if (FIREBASE_SERVICE_ACCOUNT_PATH) {
    const resolvedPath = path.isAbsolute(FIREBASE_SERVICE_ACCOUNT_PATH)
      ? FIREBASE_SERVICE_ACCOUNT_PATH
      : path.join(process.cwd(), FIREBASE_SERVICE_ACCOUNT_PATH);
    const raw = fs.readFileSync(resolvedPath, 'utf8');
    return JSON.parse(raw);
  }

  return null;
}

function getFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin;
  }

  const serviceAccount = loadServiceAccount();
  if (!serviceAccount) {
    throw new Error('Firebase Admin not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH.');
  }

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  return admin;
}

module.exports = {
  getFirebaseAdmin,
};
