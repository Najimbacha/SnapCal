const cron = require('node-cron');
const { processReminders } = require('../services/food_reminder_service');

let started = false;

function startScheduler() {
  if (started) return;
  started = true;

  // Morning: 7:00 AM
  cron.schedule('0 7 * * *', () => {
    console.log('⏰ Cron: Morning food reminder');
    processReminders().catch((err) => console.error('Morning reminder failed:', err.message));
  });

  // Lunch: 12:00 PM
  cron.schedule('0 12 * * *', () => {
    console.log('⏰ Cron: Lunch food reminder');
    processReminders().catch((err) => console.error('Lunch reminder failed:', err.message));
  });

  // Evening: 7:00 PM
  cron.schedule('0 19 * * *', () => {
    console.log('⏰ Cron: Evening food reminder');
    processReminders().catch((err) => console.error('Evening reminder failed:', err.message));
  });

  console.log('⏰ Food reminder scheduler started (7:00, 12:00, 19:00 daily)');
}

module.exports = { startScheduler };
