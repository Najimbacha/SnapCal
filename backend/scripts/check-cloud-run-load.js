// Run from any directory: node backend/scripts/check-cloud-run-load.js [imageMiB]
// Exercises the real scan route with mocked Firebase/AI in a separate process.
const { fork } = require('node:child_process');
const path = require('node:path');
const assert = require('node:assert/strict');
const imageMiB = Number(process.argv[2] || 1);
assert.ok(imageMiB > 0 && imageMiB <= 10, 'Image size must be greater than zero and at most 10MiB.');
const child = fork(path.join(__dirname, '..', 'test', 'fixtures', 'scan_load_process.cjs'), [], {
  stdio: ['ignore', 'ignore', 'ignore', 'ipc'],
});
const deadline = setTimeout(() => { child.kill(); console.error('Load check timed out'); process.exitCode = 1; }, 60000);
function message() {
  return new Promise((resolve, reject) => {
    const onMessage = value => { cleanup(); resolve(value); };
    const onExit = code => { cleanup(); reject(new Error(`Load fixture exited ${code}`)); };
    const cleanup = () => { child.off('message', onMessage); child.off('exit', onExit); };
    child.once('message', onMessage); child.once('exit', onExit);
  });
}
(async () => {
  try {
    const { port } = await message();
    const payload = JSON.stringify({ image: Buffer.alloc(Math.floor(imageMiB * 1024 * 1024), 65).toString('base64'), language: 'en' });
    const results = await Promise.all(Array.from({ length: 20 }, async () => {
      const res = await fetch(`http://127.0.0.1:${port}/v1/scan`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer mock' }, body: payload,
      });
      const body = await res.json();
      assert.ok([200, 503].includes(res.status), `Unexpected status ${res.status}`);
      if (res.status === 200) assert.ok(Array.isArray(body.items));
      else assert.equal(res.headers.get('retry-after'), '5');
      return res.status;
    }));
    assert.ok(results.includes(200), 'At least one request must complete.');
    const pending = message(); child.send('result');
    const { peakRssMiB } = await pending;
    console.log(JSON.stringify({ concurrency: 20, imageMiB, completed: results.filter(x => x === 200).length,
      shed: results.filter(x => x === 503).length, peakRssMiB,
      recommendedMemory: peakRssMiB > 409.6 ? '1Gi' : '512Mi',
      caveat: 'Local mocked backend RSS only; verify container memory with real Android images before cutover.',
    }, null, 2));
    if (peakRssMiB > 819.2) { console.error('Exceeds 80% of 1Gi. Reduce admitted image concurrency before deployment.'); process.exitCode = 1; }
  } finally { clearTimeout(deadline); child.kill(); }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
