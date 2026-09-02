// Firebase Admin bootstrap, shared by the API process and the reminder worker.
//
// This used to live inline in server.js, which meant the only way to get an
// initialized Admin SDK was to load the entire Express application — every
// route, every provider, every rate limiter. The worker needs none of that,
// so the init moved here and both entry points call it.
const admin = require('firebase-admin');

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) return admin;

  const options = {};
  if (process.env.FIREBASE_STORAGE_BUCKET) {
    options.storageBucket = process.env.FIREBASE_STORAGE_BUCKET;
  }

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      options.credential = admin.credential.cert(serviceAccount);
      admin.initializeApp(options);
      console.log('Firebase Admin initialized with service account from environment');
      return admin;
    } catch (err) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', err.message);
    }
  }

  admin.initializeApp(options);
  console.log('Firebase Admin initialized with application default credentials');
  return admin;
}

module.exports = { initializeFirebaseAdmin };
