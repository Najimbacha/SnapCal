const admin = require('firebase-admin');

const UNMATCHED_COLLECTION = 'unmatchedFoods';
let db = null;

function getDb() {
  if (!db) {
    try {
      db = admin.firestore();
    } catch (err) {
      console.error('unmatched_food_logger: Firestore not available:', err.message);
      return null;
    }
  }
  return db;
}

function normalize(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 200);
}

async function logUnmatched(foodName, metadata = {}) {
  const firestore = getDb();
  if (!firestore) return;

  const key = normalize(foodName);
  if (!key) return;

  const docRef = firestore.collection(UNMATCHED_COLLECTION).doc(key);

  try {
    await docRef.set(
      {
        foodName: foodName.slice(0, 200),
        normalizedKey: key,
        count: admin.firestore.FieldValue.increment(1),
        firstSeen: admin.firestore.FieldValue.serverTimestamp(),
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        ...metadata,
      },
      { merge: true }
    );
  } catch (err) {
    console.error('unmatched_food_logger: Failed to log:', err.message);
  }
}

async function getTopUnmatched(limit = 50) {
  const firestore = getDb();
  if (!firestore) return [];

  try {
    const snapshot = await firestore
      .collection(UNMATCHED_COLLECTION)
      .orderBy('count', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (err) {
    console.error('unmatched_food_logger: Failed to query:', err.message);
    return [];
  }
}

module.exports = { logUnmatched, getTopUnmatched };
