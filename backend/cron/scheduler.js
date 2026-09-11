const cron = require('node-cron');
const { processReminders } = require('../services/food_reminder_service');

let started = false;

function startScheduler() {
  if (started) return;
  started = true;

  // Hourly: each run sends to the users for whom it is now reminder time on
  // their own clock (see reminderDecision). Three fixed runs a day only
  // reached the time zones those hours happened to suit.
  cron.schedule('0 * * * *', () => {
    console.log('⏰ Cron: hourly food reminder run');
    processReminders().catch((err) => console.error('Food reminder run failed:', err.message));
  });

  console.log('⏰ Food reminder scheduler started (hourly)');
}

module.exports = { startScheduler };
