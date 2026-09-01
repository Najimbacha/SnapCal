const admin = require('firebase-admin');

const db = admin.firestore();

// How many settings documents one query page pulls, and the ceiling for a
// single invocation. The fan-out is time-boxed and resumable rather than
// unbounded: a run that must finish the whole base in one process is exactly
// what broke at scale.
const PAGE_SIZE = Number(process.env.REMINDER_PAGE_SIZE || 500);
const MAX_USERS_PER_RUN = Number(process.env.REMINDER_MAX_PER_RUN || 50000);
const FCM_BATCH = 500; // Firebase's per-multicast ceiling.

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
      title: `\u{1F525} Keep your ${streak} day streak alive`,
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

// Users who are actually due a reminder.
//
// The previous implementation walked `users` in pages of 200 and issued one
// `settings/app` read per user, sequentially, holding every result in memory.
// At a million registered users that is two million round-trips - roughly
// eleven hours for a job scheduled three times a day - and a heap that grows
// with the user base rather than with the work.
//
// This queries the settings documents directly through a collection group, so
// Firestore returns only users who have reminders enabled and have not been
// reminded today. Cost drops from O(all users) to O(users actually due).
// Requires the composite index in firestore.indexes.json.
async function* eligibleUserPages() {
  const today = todayKey();
  let cursor = null;
  let seen = 0;

  while (seen < MAX_USERS_PER_RUN) {
    let query = db
      .collectionGroup('settings')
      .where('foodRemindersEnabled', '==', true)
      .where('lastFoodReminderDate', '<', today)
      .orderBy('lastFoodReminderDate')
      .orderBy('__name__')
      .limit(PAGE_SIZE);

    if (cursor) query = query.startAfter(cursor);

    const snapshot = await query.get();
    if (snapshot.empty) return;

    const page = [];
    for (const doc of snapshot.docs) {
      cursor = doc;
      // A collection group matches any `settings` subcollection; keep the app doc.
      if (doc.id !== 'app') continue;

      const data = doc.data() || {};
      if (data.notificationsEnabled === false) continue;
      // Someone who already opened the app today does not need nagging.
      if ((data.lastOpenedDate || '') === today) continue;
      if (!data.fcmToken) continue;

      const uid = doc.ref.parent.parent && doc.ref.parent.parent.id;
      if (!uid) continue;

      page.push({
        uid,
        fcmToken: data.fcmToken,
        streak: typeof data.currentStreak === 'number' ? data.currentStreak : 0,
        ref: doc.ref,
      });
    }

    seen += snapshot.size;
    if (page.length > 0) yield page;
    if (snapshot.size < PAGE_SIZE) return;
  }

  console.warn(
    `FoodReminder: stopped at MAX_USERS_PER_RUN (${MAX_USERS_PER_RUN}); ` +
      'the remainder is picked up by the next run.',
  );
}

// Sends one multicast per 500 tokens instead of one request per user, and
// prunes tokens the device has invalidated - without that, an uninstalled app
// is retried three times a day forever.
async function sendBatch(users, timeOfDay) {
  if (users.length === 0) return { sent: 0, pruned: 0 };

  // Streak wording differs per user, so group by the message they receive.
  const groups = new Map();
  for (const user of users) {
    const notification = buildNotificationBody(timeOfDay, user.streak);
    const key = `${notification.title}|${notification.body}`;
    if (!groups.has(key)) groups.set(key, { notification, members: [] });
    groups.get(key).members.push(user);
  }

  let sent = 0;
  let pruned = 0;
  const today = todayKey();

  for (const { notification, members } of groups.values()) {
    for (let i = 0; i < members.length; i += FCM_BATCH) {
      const slice = members.slice(i, i + FCM_BATCH);
      const message = {
        tokens: slice.map((m) => m.fcmToken),
        notification: { title: notification.title, body: notification.body },
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
              alert: { title: notification.title, body: notification.body },
              sound: 'default',
              badge: 1,
              'mutable-content': 1,
            },
          },
        },
      };

      let responses = [];
      try {
        const result = await admin.messaging().sendEachForMulticast(message);
        responses = result.responses;
        sent += result.successCount;
      } catch (err) {
        console.error('FoodReminder: multicast failed:', err.message);
        continue;
      }

      // One batched write for the whole slice rather than a write per user.
      const writer = db.bulkWriter();
      responses.forEach((response, index) => {
        const member = slice[index];
        if (response.success) {
          writer.set(
            member.ref,
            {
              lastFoodReminderDate: today,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          return;
        }
        const code = response.error && response.error.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          pruned++;
          writer.set(
            member.ref,
            { fcmToken: admin.firestore.FieldValue.delete() },
            { merge: true },
          );
        }
      });
      await writer.close();
    }
  }

  return { sent, pruned };
}

async function processReminders() {
  const timeOfDay = getTimeOfDay();
  const startedAt = Date.now();
  console.log(`FoodReminder: processing ${timeOfDay} reminders...`);

  let total = 0;
  let sent = 0;
  let pruned = 0;

  try {
    for await (const page of eligibleUserPages()) {
      total += page.length;
      const result = await sendBatch(page, timeOfDay);
      sent += result.sent;
      pruned += result.pruned;
    }

    console.log(
      JSON.stringify({
        event: 'reminder.run',
        timeOfDay,
        eligible: total,
        sent,
        prunedTokens: pruned,
        durationMs: Date.now() - startedAt,
      }),
    );
    return { total, sent, pruned };
  } catch (err) {
    console.error('FoodReminder: process error:', err.message);
    throw err;
  }
}

module.exports = {
  processReminders,
  todayKey,
  getTimeOfDay,
  buildNotificationBody,
  eligibleUserPages,
};
