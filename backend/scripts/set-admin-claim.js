require('dotenv').config();

const { initializeAdmin } = require('./admin');

async function main() {
  const uid = process.argv[2];
  const value = process.argv[3] !== 'false';
  if (!uid || !/^[A-Za-z0-9_-]{8,80}$/.test(uid)) {
    throw new Error('Usage: npm run set-admin -- <firebaseUid> [true|false]');
  }

  const admin = initializeAdmin();
  const user = await admin.auth().getUser(uid);
  const existing = user.customClaims || {};
  await admin.auth().setCustomUserClaims(uid, { ...existing, admin: value });
  console.log(`Set admin=${value} for ${uid}. User must refresh their ID token.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
