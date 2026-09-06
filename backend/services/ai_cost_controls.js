const crypto = require('node:crypto');

// Only in-flight work is shared. Completed conversations are never retained.
function createRequestCoalescer(limit = 100) {
  const pending = new Map();
  return function coalesce(scope, request, operation) {
    const key = crypto.createHash('sha256')
      .update(JSON.stringify([scope, request])).digest('hex');
    if (pending.has(key)) {
      console.log(JSON.stringify({ event: 'ai.duplicate_avoided' }));
      return pending.get(key);
    }
    if (pending.size >= limit) return Promise.resolve().then(operation);
    const work = Promise.resolve().then(operation).finally(() => pending.delete(key));
    pending.set(key, work);
    return work;
  };
}

// Log counts supplied by the provider, never prompts, photos, or credentials.
function logAiUsage(kind, model, data) {
  const usage = data?.usage;
  if (!usage || typeof usage !== 'object') return;
  const counts = {};
  for (const key of ['prompt_tokens', 'completion_tokens', 'total_tokens',
    'prompt_cache_hit_tokens', 'prompt_cache_miss_tokens']) {
    if (Number.isFinite(usage[key]) && usage[key] >= 0) counts[key] = usage[key];
  }
  if (Object.keys(counts).length) {
    console.log(JSON.stringify({ event: 'ai.usage', kind, model, ...counts }));
  }
}

module.exports = { createRequestCoalescer, logAiUsage };
