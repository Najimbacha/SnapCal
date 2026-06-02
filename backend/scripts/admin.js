const admin = require('firebase-admin');

function initializeAdmin() {
  if (admin.apps.length > 0) return admin;

  const options = {};
  if (process.env.FIREBASE_STORAGE_BUCKET) {
    options.storageBucket = process.env.FIREBASE_STORAGE_BUCKET;
  }
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    options.credential = admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT));
  }
  admin.initializeApp(options);
  return admin;
}

module.exports = { initializeAdmin };
