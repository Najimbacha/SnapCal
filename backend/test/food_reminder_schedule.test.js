const assert = require('node:assert');
const test = require('node:test');

process.env.NODE_ENV = 'test';
require('../firebase').initializeFirebaseAdmin();

const {
  reminderDecision,
  buildNotificationBody,
  userOffsetMinutes,
} = require('../services/food_reminder_service');

const base = {
  foodRemindersEnabled: true,
  fcmToken: 'token',
  serverReminderSentOn: '1970-01-01',
  languageCode: 'en',
};

test('reminders go out around noon on the user\'s own clock', () => {
  // UTC+5: 07:30 UTC is 12:30 there.
  const due = reminderDecision({ ...base, reminderUtcOffsetMinutes: 300 }, new Date('2026-09-11T07:30:00Z'));
  assert.equal(due.due, true);
  assert.equal(due.localDate, '2026-09-11');
  assert.equal(due.timeOfDay, 'lunch');

  // 03:00 UTC is 08:00 there: too early.
  const early = reminderDecision({ ...base, reminderUtcOffsetMinutes: 300 }, new Date('2026-09-11T03:00:00Z'));
  assert.equal(early.due, false);
});

test('a user behind UTC is judged on their own date', () => {
  // UTC-7: 02:00 UTC on the 12th is 19:00 on the 11th.
  const data = { ...base, reminderUtcOffsetMinutes: -420 };
  const now = new Date('2026-09-12T02:00:00Z');
  const due = reminderDecision(data, now);
  assert.equal(due.due, true);
  assert.equal(due.localDate, '2026-09-11');
  assert.equal(due.timeOfDay, 'evening');

  assert.equal(reminderDecision({ ...data, serverReminderSentOn: '2026-09-11' }, now).due, false);
});

test('no second reminder, and none after the app was opened that day', () => {
  const now = new Date('2026-09-11T13:00:00Z');
  assert.equal(reminderDecision(base, now).due, true);
  assert.equal(reminderDecision({ ...base, serverReminderSentOn: '2026-09-11' }, now).due, false);
  assert.equal(reminderDecision({ ...base, lastOpenedDate: '2026-09-11' }, now).due, false);
  assert.equal(reminderDecision({ ...base, notificationsEnabled: false }, now).due, false);
  assert.equal(reminderDecision({ ...base, fcmToken: null }, now).due, false);
  assert.equal(reminderDecision({ ...base, foodRemindersEnabled: false }, now).due, false);
});

test('older apps with no reported offset are treated as UTC', () => {
  assert.equal(userOffsetMinutes({}), 0);
  assert.equal(userOffsetMinutes({ reminderUtcOffsetMinutes: 5000 }), 840);
  assert.equal(reminderDecision(base, new Date('2026-09-11T11:00:00Z')).due, false);
  assert.equal(reminderDecision(base, new Date('2026-09-11T12:00:00Z')).due, true);
});

test('reminders are written in the user\'s language', () => {
  const now = new Date('2026-09-11T13:00:00Z');
  const es = reminderDecision({ ...base, languageCode: 'es' }, now);
  assert.equal(es.language, 'es');
  assert.equal(buildNotificationBody(es.timeOfDay, 0, es.language).title, '¿Qué has comido hoy?');
  assert.match(buildNotificationBody('lunch', 4, 'fr').title, /série de 4 jours/);
  assert.equal(reminderDecision({ ...base, languageCode: 'de' }, now).language, 'en');
  assert.equal(buildNotificationBody('lunch', 0, 'ar').title, 'ماذا أكلت اليوم؟');
});
