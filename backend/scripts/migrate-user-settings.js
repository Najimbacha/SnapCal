require('dotenv').config();

const { initializeAdmin } = require('./admin');

const dryRun = process.argv.includes('--dry-run');
const limitArg = process.argv.find((arg) => arg.startsWith('--limit='));
const limit = limitArg ? Number(limitArg.split('=')[1]) : 100;

const appSettingKeys = [
  'themeMode',
  'languageCode',
  'onboardingComplete',
  'notificationsEnabled',
  'mealRemindersEnabled',
  'dailyMotivationEnabled',
  'breakfastTime',
  'lunchTime',
  'dinnerTime',
  'weightUnit',
  'heightUnit',
];

const profileKeys = [
  'age',
  'height',
  'startingWeight',
  'targetWeight',
  'dailyCalorieGoal',
  'dailyProteinGoal',
  'dailyCarbGoal',
  'dailyFatGoal',
  'gender',
  'activityLevel',
  'goalMode',
  'dietaryRestriction',
  'cuisinePreference',
  'mealsPerDay',
];

function pick(source, keys) {
  return keys.reduce((out, key) => {
    if (source[key] !== undefined) out[key] = source[key];
    return out;
  }, {});
}

async function main() {
  const admin = initializeAdmin();
  const db = admin.firestore();
  const users = await db.collection('users').limit(limit).get();
  let migrated = 0;

  for (const doc of users.docs) {
    const data = doc.data();
    const settings = data.settings;
    if (!settings || typeof settings !== 'object') continue;

    const appSettings = pick(settings, appSettingKeys);
    const profile = pick(settings, profileKeys);
    console.log(`[${dryRun ? 'dry-run' : 'write'}] ${doc.id}`, {
      appSettingsKeys: Object.keys(appSettings),
      profileKeys: Object.keys(profile),
      ignoredTrustedKeys: ['isPro'].filter((key) => settings[key] !== undefined),
    });

    if (!dryRun) {
      const batch = db.batch();
      batch.set(doc.ref.collection('settings').doc('app'), {
        ...appSettings,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      batch.set(doc.ref.collection('private').doc('profile'), {
        ...profile,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      await batch.commit();
    }
    migrated += 1;
  }

  console.log(`${dryRun ? 'Would migrate' : 'Migrated'} ${migrated} user documents.`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
