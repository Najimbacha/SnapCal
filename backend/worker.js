#!/usr/bin/env node
/**
 * Reminder worker — the only process that runs the food-reminder schedule.
 *
 * Why this file exists
 * --------------------
 * The scheduler was moved out of the API process, but both services still
 * booted `server.js`. That meant the worker also constructed the entire
 * Express app: every route, the rate limiters, the Redis client, the nutrition
 * database in memory. Two consequences, both avoidable:
 *
 *   - double the memory footprint for a process that sends notifications;
 *   - a fault in any API route could take down the ONE replica that is
 *     allowed to send reminders, and nothing else would send them.
 *
 * This entry point loads the Admin SDK and the scheduler, and nothing else.
 *
 * Run exactly one replica. Two replicas means every user is notified twice.
 */
require('dotenv').config();

const { initializeFirebaseAdmin } = require('./firebase');

initializeFirebaseAdmin();

const { startScheduler } = require('./cron/scheduler');
const { renderMetrics } = require('./metrics');

startScheduler();

// A worker has no inbound URL on most platforms, so its metrics would be
// unscrapeable and the reminder counters would be dead code. Serving them on a
// private port costs nothing and means the one process allowed to send
// notifications is not the one process nobody can see. Leave
// WORKER_METRICS_PORT unset and this does not listen at all.
const metricsPort = Number(process.env.WORKER_METRICS_PORT || 0);
if (metricsPort > 0) {
  require('http')
    .createServer((req, res) => {
      if (req.url !== '/metrics') {
        res.writeHead(404).end();
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/plain; version=0.0.4; charset=utf-8' });
      res.end(renderMetrics());
    })
    .listen(metricsPort, () => {
      console.log(`Worker metrics on :${metricsPort}/metrics`);
    });
}
console.log('SnapCal reminder worker started (single replica expected)');

// A crash here is not recoverable in place: the schedule is gone and no
// reminders will be sent until the platform restarts the process. Exit loudly
// so it actually restarts, rather than lingering as a live-but-idle worker.
process.on('unhandledRejection', (err) => {
  console.error('Worker unhandled rejection:', err);
  process.exit(1);
});
process.on('uncaughtException', (err) => {
  console.error('Worker uncaught exception:', err);
  process.exit(1);
});

process.on('SIGTERM', () => {
  console.log('Worker received SIGTERM, exiting.');
  process.exit(0);
});
