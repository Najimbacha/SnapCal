const { RedisStore } = require('rate-limit-redis');

function createSharedRateLimitStore(cache, prefix) {
  let options;
  let store;
  async function invoke(method, key) {
    if (!cache.isReady()) throw new Error('Rate-limit store unavailable');
    if (!store) {
      store = new RedisStore({
        prefix,
        sendCommand: (...args) => cache.getClient().sendCommand(args),
      });
      // RedisStore loads both scripts eagerly. Observe both rejections even
      // when only increment() is used; RedisStore reloads on subsequent calls.
      store.incrementScriptSha.catch(() => {});
      store.getScriptSha.catch(() => {});
      store.init(options);
    }
    let timer;
    try {
      return await Promise.race([
        store[method](key),
        new Promise((_, reject) => {
          timer = setTimeout(() => reject(new Error('Rate-limit store timeout')), 3000);
        }),
      ]);
    } finally { clearTimeout(timer); }
  }
  return {
    localKeys: false,
    prefix,
    init(value) { options = value; },
    increment: (key) => invoke('increment', key),
    decrement: (key) => invoke('decrement', key),
    resetKey: (key) => invoke('resetKey', key),
  };
}

module.exports = { createSharedRateLimitStore };
