/**
 * Shared keep-alive agents for every outbound HTTPS call.
 *
 * Node's default agent uses `keepAlive: false`, so each request to an AI
 * provider opens a new TCP connection and completes a fresh TLS handshake
 * before a single byte of the image is sent. That is roughly 100-200ms of pure
 * setup per scan, paid on every call, and it consumes an ephemeral port and a
 * file descriptor each time.
 *
 * At one scan a minute nobody notices. At a few hundred concurrent scans the
 * process runs out of ephemeral ports (they linger in TIME_WAIT for minutes
 * after close) and starts failing with ECONNRESET and EADDRNOTAVAIL — an
 * outage that looks like the provider is down when the problem is entirely
 * local. Reusing connections removes the handshake from the hot path and keeps
 * the socket count bounded.
 */
const https = require('https');
const http = require('http');

const KEEP_ALIVE_MS = Number(process.env.HTTP_KEEPALIVE_MS || 30000);
// Per-host ceiling. Bounded on purpose: unlimited sockets turn a slow provider
// into unbounded memory growth instead of visible backpressure.
const MAX_SOCKETS = Number(process.env.HTTP_MAX_SOCKETS || 128);

const httpsAgent = new https.Agent({
  keepAlive: true,
  keepAliveMsecs: KEEP_ALIVE_MS,
  maxSockets: MAX_SOCKETS,
  maxFreeSockets: 32,
  timeout: 60000,
  scheduling: 'lifo',
});

const httpAgent = new http.Agent({
  keepAlive: true,
  keepAliveMsecs: KEEP_ALIVE_MS,
  maxSockets: MAX_SOCKETS,
  maxFreeSockets: 32,
  timeout: 60000,
  scheduling: 'lifo',
});

/// Socket counts, for the metrics endpoint. Sockets climbing while requests
/// stay flat is the signature of connections leaking rather than being reused.
function agentStats() {
  const count = (obj) => Object.values(obj || {}).reduce((n, list) => n + list.length, 0);
  return {
    active: count(httpsAgent.sockets) + count(httpAgent.sockets),
    free: count(httpsAgent.freeSockets) + count(httpAgent.freeSockets),
    queued: count(httpsAgent.requests) + count(httpAgent.requests),
  };
}

module.exports = { httpsAgent, httpAgent, agentStats };
