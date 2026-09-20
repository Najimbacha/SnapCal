const test = require('node:test');
const assert = require('node:assert/strict');
const { fork } = require('node:child_process');
const { randomUUID } = require('node:crypto');
const path = require('node:path');

test('two processes share a Redis allowance and fail closed after disconnect', {
  skip: !process.env.TEST_REDIS_URL && 'Set TEST_REDIS_URL to a disposable Redis instance to run this deployment gate.',
  timeout: 20000,
}, async () => {
  const prefix = `snapcal-migration-test:${randomUUID()}:`;
  const children = [];
  async function start() {
    const child = fork(path.join(__dirname, 'fixtures', 'redis_limiter_process.cjs'), [], {
      env: { ...process.env, TEST_PREFIX: prefix }, stdio: ['ignore', 'ignore', 'inherit', 'ipc'],
    });
    children.push(child);
    const message = await new Promise((resolve, reject) => {
      child.once('message', resolve);
      child.once('error', reject);
      child.once('exit', code => reject(new Error(`Redis fixture exited ${code}`)));
    });
    assert.ok(message.port, message.error);
    return { child, url: `http://127.0.0.1:${message.port}` };
  }
  async function status(url) { const res = await fetch(url); await res.text(); return res.status; }
  try {
    const a = await start();
    const b = await start();
    assert.equal(await status(a.url), 200);
    assert.equal(await status(b.url), 200);
    assert.equal(await status(a.url), 200);
    assert.equal(await status(b.url), 429);
    const disconnected = new Promise(resolve => b.child.once('message', resolve));
    b.child.send('disconnect');
    await disconnected;
    assert.equal(await status(b.url), 503);
  } finally { for (const child of children) child.kill(); }
});
