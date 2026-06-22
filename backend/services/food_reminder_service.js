const admin = require('firebase-admin');

const db = admin.firestore();

function todayKey() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function getTimeOfDay() {
  const hour = new Date().getHours();
  if (hour < 10) return 'morning';
  if (hour < 16) return 'lunch';
  return 'evening';
}

function buildNotificationBody(timeOfDay, streak) {
  if (streak > 0) {
    return {
      title: `🔥 Keep your ${streak} day streak alive`,
      body: 'Scan your next meal and keep the momentum going.',
    };
  }

  switch (timeOfDay) {
    case 'morning':
      return {
        title: 'Good morning ☀️',
        body: 'Scan your breakfast and start tracking your day.',
      };
    case 'lunch':
      return {
        title: 'What did you eat today?',
        body: 'Open the app and scan your meal.',
      };
    case 'evening':
      return {
        title: "Don't forget your food log.",
        body: 'Scan your dinner to complete your day.',
      };
    default:
      return {
        title: 'Time to scan your food',
        body: 'Open SnapCal and log your meal.',
      };
  }
}

async function queryEligibleUsers() {
  const today = todayKey();
  const results = [];

  let lastDoc = null;
  const BATCH_SIZE = 200;

  while (true) {
    let query = db.collection('users').orderBy('__name__').limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const userSnapshot = await query.get();
    if (userSnapshot.empty) break;

    for (const userDoc of userSnapshot.docs) {
      lastDoc = userDoc;
      const uid = userDoc.id;

      try {
        const settingsSnap = await userDoc.ref.collection('settings').doc('app').get();
        if (!settingsSnap.exists) continue;

        const data = settingsSnap.data() || {};
        if (data.foodRemindersEnabled !== true) continue;
        if (data.notificationsEnabled === false) continue;

        const lastReminderDate = data.lastFoodReminderDate || '';
        if (lastReminderDate === today) continue;

        const lastOpened = data.lastOpenedDate || '';
        if (lastOpened === today) continue;

        const streak = typeof data.currentStreak === 'number' ? data.currentStreak : 0;
        const fcmToken = data.fcmToken || null;

        results.push({ uid, fcmToken, streak, data });
      } catch (err) {
        console.error(`FoodReminder: error reading settings for ${uid}:`, err.message);
      }
    }

    if (userSnapshot.docs.length < BATCH_SIZE) break;
  }

  return results;
}

async function sendFcm(token, notification, uid) {
  if (!token) {
    console.log(`FoodReminder: skipping ${uid} — no FCM token`);
    return false;
  }

  const message = {
    token,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: {
      type: 'food_reminder',
      route: '/snap',
      title: notification.title,
      body: notification.body,
    },
    android: {
      notification: {
        channelId: 'food_scan_reminders_v1',
        icon: 'ic_stat_notification',
        color: '#10B981',
        priority: 'high',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: notification.title,
            body: notification.body,
          },
          sound: 'default',
          badge: 1,
          'mutable-content': 1,
        },
      },
    },
  };

  try {
    await admin.messaging().send(message);
    console.log(`FoodReminder: sent to ${uid} (streak=${notification.title.includes('streak') ? 'yes' : 'no'})`);
    return true;
  } catch (err) {
    console.error(`FoodReminder: send failed for ${uid}:`, err.message);
    return false;
  }
}

async function trackReminderSent(uid) {
  try {
    await db.collection('users').doc(uid).collection('settings').doc('app').set({
      lastFoodReminderDate: todayKey(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  } catch (err) {
    console.error(`FoodReminder: failed to track for ${uid}:`, err.message);
  }
}

async function processReminders() {
  const timeOfDay = getTimeOfDay();
  console.log(`FoodReminder: processing ${timeOfDay} reminders...`);

  try {
    const users = await queryEligibleUsers();
    console.log(`FoodReminder: found ${users.length} eligible users`);

    let sent = 0;
    for (const user of users) {
      const notification = buildNotificationBody(timeOfDay, user.streak);
      const ok = await sendFcm(user.fcmToken, notification, user.uid);
      if (ok) {
        await trackReminderSent(user.uid);
        sent++;
      }
    }

    console.log(`FoodReminder: ${timeOfDay} done — ${sent}/${users.length} sent`);
    return { total: users.length, sent };
  } catch (err) {
    console.error('FoodReminder: process error:', err.message);
    throw err;
  }
}

module.exports = { processReminders, todayKey, getTimeOfDay, buildNotificationBody, queryEligibleUsers };
