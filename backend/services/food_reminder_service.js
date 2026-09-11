const admin = require('firebase-admin');
const { metrics } = require('../metrics');

const db = admin.firestore();

// How many settings documents one query page pulls, and the ceiling for a
// single invocation. The fan-out is time-boxed and resumable rather than
// unbounded: a run that must finish the whole base in one process is exactly
// what broke at scale.
const PAGE_SIZE = Number(process.env.REMINDER_PAGE_SIZE || 500);
const MAX_USERS_PER_RUN = Number(process.env.REMINDER_MAX_PER_RUN || 50000);
const FCM_BATCH = 500; // Firebase's per-multicast ceiling.

// One reminder a day, sent at the first run that finds the user between
// these local hours, and only if they have not opened the app that day. With
// the trigger running hourly, that is about noon wherever they are.
//
// This used to work on the server's clock alone. The server runs on UTC, so
// each user got a reminder at the first run after UTC midnight -- "Good
// morning" in the evening for much of the world -- and always in English.
const WINDOW_START_HOUR = 12;
const WINDOW_END_HOUR = 20; // the last hour a reminder may go out, inclusive
const MIN_OFFSET_MINUTES = -12 * 60;
const MAX_OFFSET_MINUTES = 14 * 60;

function dateKeyUtc(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function todayKey(now = new Date()) {
  return dateKeyUtc(now);
}

/// The user's offset from UTC, as the app last reported it. Older app versions
/// never sent one; they are treated as UTC, which is what everyone was before.
function userOffsetMinutes(data) {
  const raw = data && data.reminderUtcOffsetMinutes;
  if (typeof raw !== 'number' || !Number.isFinite(raw)) return 0;
  return Math.max(MIN_OFFSET_MINUTES, Math.min(MAX_OFFSET_MINUTES, Math.round(raw)));
}

/// The date and hour on the user's own clock.
function localClock(now, offsetMinutes) {
  const local = new Date(now.getTime() + offsetMinutes * 60000);
  return { date: dateKeyUtc(local), hour: local.getUTCHours() };
}

function getTimeOfDay(hour = new Date().getHours()) {
  if (hour < 10) return 'morning';
  if (hour < 16) return 'lunch';
  return 'evening';
}

// The app's four languages. Everyone was sent the English.
const COPY = {
  en: {
    streak: (n) => ({
      title: `\u{1F525} Keep your ${n} day streak alive`,
      body: 'Scan your next meal and keep the momentum going.',
    }),
    morning: { title: 'Good morning ☀️', body: 'Scan your breakfast and start tracking your day.' },
    lunch: { title: 'What did you eat today?', body: 'Open the app and scan your meal.' },
    evening: { title: "Don't forget your food log.", body: 'Scan your dinner to complete your day.' },
    fallback: { title: 'Time to scan your food', body: 'Open SnapCal and log your meal.' },
  },
  es: {
    streak: (n) => ({
      title: `\u{1F525} Mantén tu racha de ${n} días`,
      body: 'Escanea tu próxima comida y sigue así.',
    }),
    morning: { title: 'Buenos días ☀️', body: 'Escanea tu desayuno y empieza a registrar tu día.' },
    lunch: { title: '¿Qué has comido hoy?', body: 'Abre la app y escanea tu comida.' },
    evening: { title: 'No olvides tu registro de comidas.', body: 'Escanea tu cena para completar el día.' },
    fallback: { title: 'Hora de escanear tu comida', body: 'Abre SnapCal y registra tu comida.' },
  },
  fr: {
    streak: (n) => ({
      title: `\u{1F525} Gardez votre série de ${n} jours`,
      body: 'Scannez votre prochain repas et gardez le rythme.',
    }),
    morning: { title: 'Bonjour ☀️', body: 'Scannez votre petit-déjeuner et commencez à suivre votre journée.' },
    lunch: { title: "Qu'avez-vous mangé aujourd'hui ?", body: "Ouvrez l'app et scannez votre repas." },
    evening: { title: "N'oubliez pas votre journal alimentaire.", body: 'Scannez votre dîner pour compléter votre journée.' },
    fallback: { title: 'Il est temps de scanner votre repas', body: 'Ouvrez SnapCal et enregistrez votre repas.' },
  },
  ar: {
    streak: (n) => ({
      title: `\u{1F525} حافظ على سلسلة ${n} يومًا`,
      body: 'امسح وجبتك التالية وواصل التقدم.',
    }),
    morning: { title: 'صباح الخير ☀️', body: 'امسح فطورك وابدأ تتبع يومك.' },
    lunch: { title: 'ماذا أكلت اليوم؟', body: 'افتح التطبيق وامسح وجبتك.' },
    evening: { title: 'لا تنسَ سجل طعامك.', body: 'امسح عشاءك لتكمل يومك.' },
    fallback: { title: 'حان وقت مسح طعامك', body: 'افتح SnapCal وسجّل وجبتك.' },
  },
};

function reminderLanguage(code) {
  return Object.prototype.hasOwnProperty.call(COPY, code) ? code : 'en';
}

function buildNotificationBody(timeOfDay, streak, language = 'en') {
  const copy = COPY[reminderLanguage(language)];
  if (streak > 0) return copy.streak(streak);
  return copy[timeOfDay] || copy.fallback;
}

/// Whether one settings document is due a reminder now, judged on the user's
/// own clock, and in which words.
function reminderDecision(data, now = new Date()) {
  if (!data || data.foodRemindersEnabled !== true) return { due: false };
  if (data.notificationsEnabled === false) return { due: false };
  if (!data.fcmToken) return { due: false };
  const clock = localClock(now, userOffsetMinutes(data));
  // Already reminded today, on their calendar.
  if ((data.serverReminderSentOn || '') >= clock.date) return { due: false };
  // Someone who already opened the app today does not need nagging.
  if ((data.lastOpenedDate || '') === clock.date) return { due: false };
  if (clock.hour < WINDOW_START_HOUR || clock.hour > WINDOW_END_HOUR) return { due: false };
  return {
    due: true,
    localDate: clock.date,
    timeOfDay: getTimeOfDay(clock.hour),
    language: reminderLanguage(data.languageCode),
  };
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
//
// The tracking field is `serverReminderSentOn`, NOT `lastFoodReminderDate`.
// That is deliberate and it is the whole reason this can ship independently of
// the app. `lastFoodReminderDate` is a field every released version of the
// client writes on every settings save, with whatever its local copy holds --
// usually null. Any rule strong enough to stop that from erasing the server's
// write also rejects the entire settings document from those older apps, which
// would mean waiting for Play Store adoption before deploying rules.
//
// A field no shipped client knows about needs no such rule: old apps never
// send it, so they can never clear it, and their writes keep working untouched.
// `lastFoodReminderDate` survives as a legacy field that nothing reads.
async function* eligibleUserPages(now = new Date()) {
  // The latest calendar date anywhere on Earth right now. Anyone last reminded
  // before it may be due somewhere in their own day; the exact test, on the
  // user's clock, is reminderDecision() below.
  const latestDate = dateKeyUtc(new Date(now.getTime() + MAX_OFFSET_MINUTES * 60000));
  let cursor = null;
  let seen = 0;

  while (seen < MAX_USERS_PER_RUN) {
    let query = db
      .collectionGroup('settings')
      .where('foodRemindersEnabled', '==', true)
      .where('serverReminderSentOn', '<', latestDate)
      .orderBy('serverReminderSentOn')
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
      const decision = reminderDecision(data, now);
      if (!decision.due) continue;

      const uid = doc.ref.parent.parent && doc.ref.parent.parent.id;
      if (!uid) continue;

      page.push({
        uid,
        fcmToken: data.fcmToken,
        streak: typeof data.currentStreak === 'number' ? data.currentStreak : 0,
        ref: doc.ref,
        localDate: decision.localDate,
        timeOfDay: decision.timeOfDay,
        language: decision.language,
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
async function sendBatch(users) {
  if (users.length === 0) return { sent: 0, pruned: 0 };

  // Streak wording differs per user, so group by the message they receive.
  const groups = new Map();
  for (const user of users) {
    const notification = buildNotificationBody(user.timeOfDay, user.streak, user.language);
    const key = `${notification.title}|${notification.body}`;
    if (!groups.has(key)) groups.set(key, { notification, members: [] });
    groups.get(key).members.push(user);
  }

  let sent = 0;
  let pruned = 0;
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
        metrics.reminderRuns.inc({ outcome: 'sent' }, result.successCount);
        metrics.reminderRuns.inc(
          { outcome: 'rejected' },
          slice.length - result.successCount,
        );
      } catch (err) {
        console.error('FoodReminder: multicast failed:', err.message);
        metrics.reminderRuns.inc({ outcome: 'batch_failed' }, slice.length);
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
              serverReminderSentOn: member.localDate,
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
          metrics.reminderRuns.inc({ outcome: 'token_pruned' });
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

async function processReminders(now = new Date()) {
  const startedAt = Date.now();
  console.log('FoodReminder: processing reminders due on each user\'s clock...');

  let total = 0;
  let sent = 0;
  let pruned = 0;

  try {
    for await (const page of eligibleUserPages(now)) {
      total += page.length;
      const result = await sendBatch(page);
      sent += result.sent;
      pruned += result.pruned;
    }

    console.log(
      JSON.stringify({
        event: 'reminder.run',
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
  reminderDecision,
  localClock,
  userOffsetMinutes,
};
