require('dotenv').config();

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const axios = require('axios');
const { httpsAgent, httpAgent, agentStats } = require('./http_agents');

// Applied globally rather than per call site: a call that forgets the agent
// silently falls back to a new connection per request, which is exactly the
// bug this prevents and is invisible until the socket count explodes.
axios.defaults.httpsAgent = httpsAgent;
axios.defaults.httpAgent = httpAgent;
const admin = require('firebase-admin');
const rateLimit = require('express-rate-limit');

// A 10mb ceiling on every route meant any endpoint could be used to make the
// process buffer 10MB per concurrent request. Image routes opt in explicitly.
const MAX_JSON_BODY = process.env.MAX_JSON_BODY || '2mb';
const MAX_IMAGE_BODY = process.env.MAX_IMAGE_BODY || '14mb';
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const FREE_MONTHLY_SCANS = Number(process.env.FREE_MONTHLY_SCANS || 3);

// Bonus scans earned by watching a rewarded ad.
//
// The client has always granted these locally, in SharedPreferences, while the
// server counted only FREE_MONTHLY_SCANS -- so a user watched an ad, was told
// "+1 bonus scan unlocked", and then had that scan refused with a 402. The
// server now keeps the count, and the cap bounds what a forged call could ever
// be worth.
const MAX_BONUS_SCANS_PER_MONTH = Number(process.env.MAX_BONUS_SCANS_PER_MONTH || 10);
const FREE_DAILY_AI_MESSAGES = Number(process.env.FREE_DAILY_AI_MESSAGES || 1);
// Fail closed: App Check is ON unless explicitly disabled. A misspelled or
// unset variable must never silently disable the control (BUG-006).
const REQUIRE_APP_CHECK = process.env.REQUIRE_APP_CHECK !== 'false';
const REVENUECAT_WEBHOOK_AUTH = process.env.REVENUECAT_WEBHOOK_AUTH || '';
const REVENUECAT_SECRET_API_KEY = process.env.REVENUECAT_SECRET_API_KEY || '';
// RevenueCat event types that end entitlement access at once. Everything
// else (CANCELLATION, BILLING_ISSUE, PRODUCT_CHANGE, RENEWAL, ...) leaves
// the user active until expiration_at_ms passes, which getPremiumStatus()
// re-checks on every read.
const REVOKES_ACCESS_IMMEDIATELY = ['EXPIRATION', 'REFUND', 'SUBSCRIPTION_PAUSED'];
const NODE_ENV = process.env.NODE_ENV || 'development';

if (NODE_ENV === 'production' && !REQUIRE_APP_CHECK) {
  throw new Error(
    'Refusing to start in production with App Check disabled. ' +
      'Set REQUIRE_APP_CHECK=true to boot.',
  );
}

const redisCache = require('./redis');
const {
  tryAcquireScanSlot,
  releaseScanSlot,
  scanConcurrency,
  providerAvailable,
  recordProviderSuccess,
  recordProviderFailure,
  breakerStates,
} = require('./scan_guard');
const {
  httpMetricsMiddleware,
  renderMetrics,
  metrics,
} = require('./metrics');
const { initializeFirebaseAdmin } = require('./firebase');

initializeFirebaseAdmin();

const SCAN_PIPELINE = (process.env.SCAN_PIPELINE || 'v1').toLowerCase();
const nutritionProvider = require('./services/nutrition_provider');
const unmatchedFoodLogger = require('./services/unmatched_food_logger');

const app = express();
const db = admin.firestore();
let authVerifierForTest = null;

app.disable('x-powered-by');
app.set('trust proxy', Number(process.env.TRUST_PROXY_COUNT) || 1);
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

// Deny-by-default: an empty ALLOWED_ORIGINS must reject browser origins, not
// permit every one of them. Native mobile requests carry no Origin header and
// are unaffected (BUG-006).
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || ALLOWED_ORIGINS.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
}));
app.use(morgan(process.env.NODE_ENV === 'test' ? 'combined' : 'dev'));
// Records rate, errors and duration for every request. Mounted before the
// body parsers so the timing covers parsing too, which is where a large
// image payload actually spends its first hundred milliseconds.
app.use(httpMetricsMiddleware);
// Image-bearing routes get the large parser; everything else gets 2mb. The
// base64 expansion factor is ~1.37, so 14mb covers the 10MB image cap.
const imageBodyParser = express.json({
  limit: MAX_IMAGE_BODY,
  type: 'application/json',
});
app.use('/v1/scan', imageBodyParser);
app.use('/api/ai/image', imageBodyParser);
app.use(express.json({ limit: MAX_JSON_BODY, type: 'application/json' }));
app.use(express.urlencoded({ limit: MAX_JSON_BODY, extended: false }));

// ── Rate limiting ────────────────────────────────────────────────────────────
//
// Two problems with the previous configuration, both of which only appear at
// scale. It used the default MemoryStore, so every limit was per-process:
// three instances meant three times the configured quota, and a deploy reset
// every counter. And it keyed on IP, which on mobile means carrier-grade NAT —
// thousands of real users sharing one address trip the window while an abuser
// simply rotates addresses.
//
// The store is Redis when REDIS_URL is set (shared across instances, survives
// a deploy), and the in-memory default otherwise so local development needs no
// extra service. The connection is shared with the entitlement cache; see
// redis.js.
let limiterStoreFactory = () => undefined;

redisCache.init();
if (redisCache.getClient()) {
  try {
    const { RedisStore } = require('rate-limit-redis');
    limiterStoreFactory = (prefix) =>
      new RedisStore({
        prefix,
        sendCommand: (...args) => redisCache.getClient().sendCommand(args),
      });
    console.log('Rate limiting backed by Redis');
  } catch (error) {
    console.error(
      'REDIS_URL set but the Redis store could not load:',
      error.message,
    );
  }
} else if (NODE_ENV === 'production') {
  console.warn(
    'WARNING: no REDIS_URL. Rate limits are per-instance and reset on deploy, ' +
      'and every premium-status read hits Firestore.',
  );
}

/// Buckets by identity, not by address.
///
/// After authenticateToken the uid is authoritative. Limiters that run before
/// it (the /api mount) fall back to a hash of the bearer token, which is
/// per-user and unforgeable — a caller cannot claim someone else's bucket
/// without their token. Unauthenticated callers still bucket by IP.
function identityKey(req) {
  if (req.user && req.user.uid) return `uid:${req.user.uid}`;
  const match = (req.headers.authorization || '').match(/^Bearer (.+)$/);
  if (match) {
    return `tok:${crypto.createHash('sha256').update(match[1]).digest('hex').slice(0, 32)}`;
  }
  return `ip:${req.ip}`;
}

function makeLimiter({ prefix, windowMs, max, message }) {
  return rateLimit({
    windowMs,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: identityKey,
    store: limiterStoreFactory(prefix),
    ...(message ? { message } : {}),
  });
}

const apiLimiter = makeLimiter({
  prefix: 'rl:api:',
  windowMs: 15 * 60 * 1000,
  max: Number(process.env.API_RATE_LIMIT || 120),
  message: { error: 'Too many requests. Please try again later.' },
});

const scanLimiter = makeLimiter({
  prefix: 'rl:scan:',
  windowMs: 15 * 60 * 1000,
  max: Number(process.env.SCAN_RATE_LIMIT || 20),
  message: { error: 'Too many scan requests. Please try again later.' },
});

const webhookLimiter = makeLimiter({
  prefix: 'rl:hook:',
  windowMs: 60 * 1000,
  max: Number(process.env.WEBHOOK_RATE_LIMIT || 120),
});

function getLanguageName(code) {
  switch (code) {
    case 'ar':
      return 'Arabic';
    case 'es':
      return 'Spanish';
    case 'fr':
      return 'French';
    default:
      return 'English';
  }
}

function getNotFoodTranslation(code) {
  switch (code) {
    case 'ar':
      return { food_name: 'ليس طعاماً', insights: ['كائن غير صالح'] };
    case 'es':
      return { food_name: 'No es comida', insights: ['Objeto no válido'] };
    case 'fr':
      return { food_name: 'Pas de la nourriture', insights: ['Objet invalide'] };
    default:
      return { food_name: 'Not food', insights: ['Invalid Object'] };
  }
}

function getSystemPrompt(languageCode) {
  const languageName = getLanguageName(languageCode);
  const notFood = getNotFoodTranslation(languageCode);

  return `You are a Nutritionist AI analyzing food images.

STRICT LANGUAGE RULE:
- YOU MUST RESPOND ENTIRELY IN THE ${languageName} LANGUAGE.
- All fields like "food_name", "portion", and "insights" MUST be in ${languageName}.
- Use native, common culinary terms for ${languageName}.

Identify this food and estimate calories, protein, carbs, and fat per serving. Return as JSON.
Output ONLY a raw JSON object with no markdown formatting, no code blocks, no explanatory text.

Return this exact structure:
{
  "items": [
    {
      "food_name": "string",
      "portion": "string",
      "calories": number,
      "protein": number,
      "carbs": number,
      "fat": number,
      "health_score": number,
      "insights": ["string", "string"],
      "alternatives": ["string", "string"]
    }
  ]
}

Rules:
- Each distinct food item visible on the plate gets its own entry in the "items" array
- health_score is based on nutritional density (10 = superfood, 1 = junk food)
- insights should be short positive or cautionary highlights
- alternatives must be 2-3 similar foods the item could plausibly be (e.g. "Oatmeal", "Porridge", "Cream of Wheat"). These help the user correct the AI if it guessed wrong. Keep them short (1-3 words each).
- All nutritional values are for a typical single serving
- protein, carbs, fat are in grams
- If NOT food at all, return: {"items": [{"food_name": "${notFood.food_name}", "health_score": 0, "insights": ["${notFood.insights[0]}"], "alternatives": [], "calories": 0, "protein": 0, "carbs": 0, "fat": 0}]}`;
}

function getV2SystemPrompt(languageCode) {
  const languageName = getLanguageName(languageCode);

  return `Analyze this food photo as a food detector.

STRICT LANGUAGE RULE:
- The "name" field MUST be in ${languageName}. Use native, common culinary terms.
- The "match_key" field MUST ALWAYS be in ENGLISH, regardless of the language above.

Your ONLY task is to:
1. Identify each distinct serving or dish in the photo
2. Give it a localised display name AND an English match_key
3. Estimate its weight in grams
4. Assign a confidence score (0.0 to 1.0)

Do NOT calculate any nutritional values (calories, protein, carbs, fat).
Do NOT provide health scores, insights, or alternatives.

Output ONLY a raw JSON object with no markdown formatting, no code blocks, no explanatory text.

Return this exact structure:
{
  "foods": [
    {
      "name": "string",
      "match_key": "string",
      "estimated_weight_g": number,
      "confidence": number
    }
  ]
}

Rules:
- Treat an assembled/composite dish as ONE single item (e.g. burger, cheeseburger, sandwich, sub, taco, wrap, pizza, hot dog, burrito). Do NOT list its components (bun, patty, lettuce, toppings, sauce) separately.
- Only create more than one entry when the photo clearly shows separate, side-by-side servings (e.g. a burger NEXT TO fries = two items; a burger by itself = one item).
- match_key is the food's common ENGLISH name, lowercase, no punctuation, no brand.
  Include the preparation when it changes how the food is cooked
  (e.g. "fried chicken", "grilled chicken breast", "boiled egg", "white rice").
  This field is used to look the food up in a nutrition database, so be literal
  and conventional rather than descriptive.
- estimated_weight_g is your best estimate of the weight of that item in grams for the portion visible.
  If you genuinely cannot estimate a weight, omit the field rather than guessing 0.
- confidence is a score from 0.0 (not confident) to 1.0 (very confident)
- Do NOT include any nutritional information
- If NOT food at all, return: {"foods": []}`;
}

function safeCompare(a, b) {
  const bufA = Buffer.from(String(a || ''));
  const bufB = Buffer.from(String(b || ''));
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}

function safeError(res, status, message) {
  return res.status(status).json({ error: message });
}

function isSafeId(value) {
  return typeof value === 'string' && /^[A-Za-z0-9_-]{8,80}$/.test(value);
}

function isSafeFileName(value) {
  return typeof value === 'string' && /^[A-Za-z0-9_.-]{1,120}$/.test(value) && !value.includes('..');
}

function cleanLanguage(value) {
  return ['en', 'ar', 'es', 'fr'].includes(value) ? value : 'en';
}

function assertPlainObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value);
}

async function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) {
    metrics.authFailures.inc({ control: 'auth_missing' });
    return safeError(res, 401, 'Authentication required.');
  }

  try {
    // checkRevoked was true here for every request. That flag makes the Admin
    // SDK fetch the user record from Google on each call instead of verifying
    // the signature locally, so every authenticated request carried a network
    // round-trip (30-80ms) and an external quota. ID tokens live one hour;
    // routes that genuinely need immediate revocation use requireFreshAuth.
    const decodedToken = authVerifierForTest
      ? await authVerifierForTest(match[1])
      : await admin.auth().verifyIdToken(match[1]);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || null,
      admin: decodedToken.admin === true,
    };
    return next();
  } catch (error) {
    metrics.authFailures.inc({ control: 'auth_invalid' });
    console.error('Auth token rejected:', error.message);
    return safeError(res, 401, 'Authentication required.');
  }
}

async function verifyAppCheck(req, res, next) {
  if (!REQUIRE_APP_CHECK) return next();
  const token = req.header('X-Firebase-AppCheck');
  if (!token) {
    metrics.authFailures.inc({ control: 'appcheck_missing' });
    return safeError(res, 401, 'App Check required.');
  }
  try {
    await admin.appCheck().verifyToken(token);
    return next();
  } catch (error) {
    metrics.authFailures.inc({ control: 'appcheck_invalid' });
    console.error('App Check token rejected:', error.message);
    return safeError(res, 401, 'App Check required.');
  }
}

/// Re-verifies the caller's token with revocation checking.
///
/// Costs a round-trip to Firebase Auth, so it is reserved for routes where a
/// stolen or revoked session must stop working within the hour rather than at
/// token expiry: anything under /api/admin, and account-level changes.
async function requireFreshAuth(req, res, next) {
  if (authVerifierForTest) return next();
  const match = (req.headers.authorization || '').match(/^Bearer (.+)$/);
  if (!match) return safeError(res, 401, 'Authentication required.');
  try {
    await admin.auth().verifyIdToken(match[1], true);
    return next();
  } catch (error) {
    metrics.authFailures.inc({ control: 'revoked' });
    console.error('Revocation check failed:', error.message);
    return safeError(res, 401, 'Authentication required.');
  }
}

function requireAdmin(req, res, next) {
  if (req.user?.admin === true) return next();
  metrics.authFailures.inc({ control: 'not_admin' });
  return safeError(res, 403, 'Permission denied.');
}

function userDoc(uid) {
  return db.collection('users').doc(uid);
}

function scanDoc(uid, scanId) {
  return userDoc(uid).collection('foodScans').doc(scanId);
}

function usageDoc(uid) {
  return userDoc(uid).collection('usage').doc('currentMonth');
}

function subscriptionDoc(uid) {
  return userDoc(uid).collection('subscription').doc('current');
}

function currentMonthKey() {
  const now = new Date();
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
}

/// This month's bonus scans, ignoring a stale month's leftovers.
///
/// Bonus scans expire with the month exactly like the free allowance: the
/// usage document carries one monthKey, and anything stamped with a different
/// one is last month's and does not count.
function bonusScansFor(usage, monthKey) {
  if (!usage || usage.monthKey !== monthKey) return 0;
  const raw = Number(usage.bonusScans || 0);
  if (!Number.isFinite(raw) || raw <= 0) return 0;
  return Math.min(Math.floor(raw), MAX_BONUS_SCANS_PER_MONTH);
}

/// Total scans a non-premium user may take this month.
function freeAllowanceFor(usage, monthKey) {
  return FREE_MONTHLY_SCANS + bonusScansFor(usage, monthKey);
}

function currentDayKey() {
  return new Date().toISOString().slice(0, 10);
}

// Claims one free AI coach message, transactionally.
//
// The client counts these too (PremiumGateService), but a client-side counter
// is cleared by reinstalling, so the ceiling was effectively unlimited. This is
// the enforcing copy. Throws a 402 when a free user is out for the day.
async function claimAiMessageQuota(uid) {
  return db.runTransaction(async (tx) => {
    const subRef = subscriptionDoc(uid);
    const useRef = usageDoc(uid);
    const [subSnap, useSnap] = await Promise.all([tx.get(subRef), tx.get(useRef)]);

    const subscription = subSnap.exists ? subSnap.data() : {};
    const expiresDate = subscription?.expiresAt?.toDate ? subscription.expiresAt.toDate() : null;
    const isPremium = subscription?.isActive === true && (!expiresDate || expiresDate > new Date());
    if (isPremium) return { isPremium: true };

    const usage = useSnap.exists ? useSnap.data() : {};
    const dayKey = currentDayKey();
    const used = usage.aiDayKey === dayKey ? Number(usage.aiMessagesUsed || 0) : 0;

    if (used >= FREE_DAILY_AI_MESSAGES) {
      throw Object.assign(new Error('ai-quota-exceeded'), { code: 402 });
    }

    tx.set(useRef, {
      aiDayKey: dayKey,
      aiMessagesUsed: used + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { isPremium: false };
  });
}

// How long a RevenueCat REST verification is trusted before we ask again.
// Bounds the fallback below to roughly one call per user per interval.
const REVENUECAT_RECHECK_MS = Number(process.env.REVENUECAT_RECHECK_MS || 10 * 60 * 1000);

// Reads the entitlement straight from RevenueCat.
//
// `subscription/current` is written by the webhook, which can be late, retried,
// or misconfigured. When it is, a user who has genuinely paid looks inactive to
// every caller of getPremiumStatus(). This makes the webhook an optimisation
// instead of a single point of failure. Returns null when no key is configured
// or the call fails -- callers must treat null as "unknown", never as "free".
async function fetchRevenueCatEntitlement(uid) {
  if (!REVENUECAT_SECRET_API_KEY) return null;

  try {
    const response = await axios.get(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
      {
        headers: { Authorization: `Bearer ${REVENUECAT_SECRET_API_KEY}` },
        timeout: 8000,
        validateStatus: (status) => status === 200 || status === 404,
      },
    );
    if (response.status === 404) {
      return { isActive: false, entitlementId: null, productId: null, expiresMs: 0 };
    }

    const entitlements = response.data?.subscriber?.entitlements || {};
    const now = Date.now();
    let best = null;
    for (const [entitlementId, entitlement] of Object.entries(entitlements)) {
      const expiresMs = entitlement?.expires_date
        ? Date.parse(entitlement.expires_date)
        : 0;
      const isActive = expiresMs === 0 || (Number.isFinite(expiresMs) && expiresMs > now);
      const candidate = {
        entitlementId,
        productId: entitlement?.product_identifier || null,
        expiresMs: Number.isFinite(expiresMs) ? expiresMs : 0,
        isActive,
      };
      // Prefer an active entitlement, and among those the one lasting longest.
      if (!best) best = candidate;
      else if (candidate.isActive && !best.isActive) best = candidate;
      else if (candidate.isActive === best.isActive && candidate.expiresMs === 0) best = candidate;
      else if (candidate.isActive === best.isActive && best.expiresMs !== 0 && candidate.expiresMs > best.expiresMs) best = candidate;
    }

    return best || { isActive: false, entitlementId: null, productId: null, expiresMs: 0 };
  } catch (error) {
    console.error('RevenueCat REST verification failed:', error.message);
    return null;
  }
}

// How long a cached entitlement may be served. Short on purpose: this is the
// window in which a refund or expiry is not yet reflected. Every path that
// genuinely changes entitlement (webhook, admin grant/revoke, debug routes)
// invalidates the key explicitly, so the TTL only covers changes the server
// never saw.
const ENTITLEMENT_CACHE_TTL = Number(process.env.ENTITLEMENT_CACHE_TTL || 60);

function entitlementCacheKey(uid) {
  return `ent:v1:${uid}`;
}

/// Drops a user's cached entitlement. Call this from anywhere that changes
/// what the answer should be — a stale Pro flag is a support ticket, a stale
/// free flag is a paying customer who cannot use what they bought.
async function invalidateEntitlement(uid) {
  if (!uid) return;
  await redisCache.del(entitlementCacheKey(uid));
}

async function loadEntitlement(uid) {
  const snap = await subscriptionDoc(uid).get();
  metrics.firestoreOps.inc({ operation: 'get', collection: 'subscription' });
  let data = snap.exists ? snap.data() : {};
  let expiresAt = data?.expiresAt;
  let expiresDate = expiresAt?.toDate ? expiresAt.toDate() : null;
  let active = data?.isActive === true && (!expiresDate || expiresDate > new Date());

  // Webhook fallback. Only runs when the mirror says "not active", and is
  // throttled by lastRestCheckAt so a genuinely free user costs one call per
  // REVENUECAT_RECHECK_MS rather than one per request.
  if (!active && REVENUECAT_SECRET_API_KEY) {
    const lastCheck = data?.lastRestCheckAt?.toMillis ? data.lastRestCheckAt.toMillis() : 0;
    if (Date.now() - lastCheck > REVENUECAT_RECHECK_MS) {
      const verified = await fetchRevenueCatEntitlement(uid);
      if (verified) {
        const payload = {
          lastRestCheckAt: admin.firestore.FieldValue.serverTimestamp(),
          source: 'revenuecat_rest',
          updatedByServer: true,
        };
        if (verified.isActive) {
          payload.isActive = true;
          payload.entitlementId = verified.entitlementId || 'pro';
          payload.productId = verified.productId;
          payload.expiresAt = verified.expiresMs
            ? admin.firestore.Timestamp.fromMillis(verified.expiresMs)
            : null;
          payload.lastVerifiedAt = admin.firestore.FieldValue.serverTimestamp();

          active = true;
          expiresAt = payload.expiresAt;
          expiresDate = verified.expiresMs ? new Date(verified.expiresMs) : null;
          // Merge the plain values only. The serverTimestamp() sentinels above
          // are write instructions, not data, and must not reach the response.
          data = {
            ...data,
            isActive: true,
            entitlementId: payload.entitlementId,
            productId: payload.productId,
            expiresAt: payload.expiresAt,
            source: 'revenuecat_rest',
            lastVerifiedAt: admin.firestore.Timestamp.now(),
          };
        }
        try {
          await subscriptionDoc(uid).set(payload, { merge: true });
          // This path runs on a cache MISS and its result is about to be
          // cached by the caller, so there is nothing to invalidate here --
          // but the mirror write means the next miss is cheap.
        } catch (error) {
          console.error('Subscription mirror write failed:', error.message);
        }
      }
    }
  }

  return {
    isActive: active,
    entitlementId: data?.entitlementId || null,
    productId: data?.productId || null,
    expiresAt: expiresAt || null,
    source: data?.source || null,
    lastVerifiedAt: data?.lastVerifiedAt || null,
  };
}

/// The entitlement half is cached; the quota half never is.
///
/// The client calls this on every launch and the answer is read-mostly, so a
/// short cache removes the Firestore read from the hot path entirely for Pro
/// users. `scansRemaining` is deliberately left out of the cache: it changes on
/// every scan, and showing a free user a stale count is exactly the confusion
/// the server-authoritative quota was introduced to end.
///
/// The cached value is stored as its own JSON round-trip so a cache hit and a
/// cache miss serialise byte-identically on the wire — a Firestore Timestamp
/// and its `{_seconds,_nanoseconds}` form must not be a visible difference.
async function getPremiumStatus(uid) {
  let entitlement = await redisCache.getJson(entitlementCacheKey(uid));

  if (entitlement) {
    metrics.entitlementCache.inc({ result: 'hit' });
  } else {
    metrics.entitlementCache.inc({ result: 'miss' });
    const fresh = await loadEntitlement(uid);
    entitlement = JSON.parse(JSON.stringify(fresh));
    await redisCache.setJson(entitlementCacheKey(uid), entitlement, ENTITLEMENT_CACHE_TTL);
  }

  // Mirror the authoritative monthly quota so the client displays what the
  // server will actually enforce, instead of its own local guess (BUG-005).
  let scansRemaining = null;
  let bonusScans = 0;
  let scanAllowance = FREE_MONTHLY_SCANS;
  if (!entitlement.isActive) {
    try {
      const useSnap = await usageDoc(uid).get();
      metrics.firestoreOps.inc({ operation: 'get', collection: 'usage' });
      const usage = useSnap.exists ? useSnap.data() : {};
      const monthKey = currentMonthKey();
      const scansUsed = usage.monthKey === monthKey ? Number(usage.scansUsed || 0) : 0;
      bonusScans = bonusScansFor(usage, monthKey);
      scanAllowance = freeAllowanceFor(usage, monthKey);
      scansRemaining = Math.max(0, scanAllowance - scansUsed);
    } catch (error) {
      console.error('Usage read failed for premium status:', error.message);
    }
  }

  return {
    ...entitlement,
    // monthlyScanLimit is the base allowance and stays what it always was, so
    // existing clients keep reading the same field. scanAllowance is that plus
    // this month's earned bonus -- the number the server actually enforces.
    monthlyScanLimit: FREE_MONTHLY_SCANS,
    bonusScans,
    scanAllowance,
    maxBonusScansPerMonth: MAX_BONUS_SCANS_PER_MONTH,
    scansRemaining,
  };
}

async function claimScanQuota(uid, scanId) {
  return db.runTransaction(async (tx) => {
    const subRef = subscriptionDoc(uid);
    const useRef = usageDoc(uid);
    const scanRef = scanDoc(uid, scanId);
    const [subSnap, useSnap, scanSnap] = await Promise.all([
      tx.get(subRef),
      tx.get(useRef),
      tx.get(scanRef),
    ]);

    if (!scanSnap.exists) {
      throw Object.assign(new Error('scan-not-found'), { code: 404 });
    }

    const scan = scanSnap.data();
    if (scan.status !== 'uploaded' && scan.status !== 'failed') {
      throw Object.assign(new Error('scan-not-processable'), { code: 409 });
    }

    const subscription = subSnap.exists ? subSnap.data() : {};
    const expiresDate = subscription?.expiresAt?.toDate ? subscription.expiresAt.toDate() : null;
    const isPremium = subscription?.isActive === true && (!expiresDate || expiresDate > new Date());
    const usage = useSnap.exists ? useSnap.data() : {};
    const monthKey = currentMonthKey();
    const scansUsed = usage.monthKey === monthKey ? Number(usage.scansUsed || 0) : 0;

    if (!isPremium && scansUsed >= freeAllowanceFor(usage, monthKey)) {
      throw Object.assign(new Error('quota-exceeded'), { code: 402 });
    }

    tx.set(useRef, {
      monthKey,
      scansUsed: scansUsed + 1,
      premiumScansUsed: isPremium ? Number(usage.premiumScansUsed || 0) + 1 : Number(usage.premiumScansUsed || 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    tx.update(scanRef, {
      status: 'processing',
      processingError: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return scan;
  });
}

// Transactional quota claim for the stateless /v1/scan endpoint (BUG-011).
// The increment is committed BEFORE the AI call so parallel requests cannot
// all read the same scansUsed and slip past the check during the 20-60s
// processing window. Returns the premium flag at claim time.
async function claimScanQuotaForScan(uid) {
  return db.runTransaction(async (tx) => {
    const subRef = subscriptionDoc(uid);
    const useRef = usageDoc(uid);
    const [subSnap, useSnap] = await Promise.all([tx.get(subRef), tx.get(useRef)]);

    const subscription = subSnap.exists ? subSnap.data() : {};
    const expiresDate = subscription?.expiresAt?.toDate ? subscription.expiresAt.toDate() : null;
    const isPremium = subscription?.isActive === true && (!expiresDate || expiresDate > new Date());
    const usage = useSnap.exists ? useSnap.data() : {};
    const monthKey = currentMonthKey();
    const scansUsed = usage.monthKey === monthKey ? Number(usage.scansUsed || 0) : 0;

    if (!isPremium && scansUsed >= freeAllowanceFor(usage, monthKey)) {
      throw Object.assign(new Error('quota-exceeded'), { code: 402 });
    }

    tx.set(useRef, {
      monthKey,
      scansUsed: scansUsed + 1,
      premiumScansUsed: isPremium ? Number(usage.premiumScansUsed || 0) + 1 : Number(usage.premiumScansUsed || 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { isPremium, monthKey };
  });
}

// Best-effort refund when the AI call fails after a successful claim, so a
// broken provider does not consume a user's quota.
async function refundScanQuota(uid, claimedMonthKey) {
  try {
    await db.runTransaction(async (tx) => {
      const useRef = usageDoc(uid);
      const useSnap = await tx.get(useRef);
      const usage = useSnap.exists ? useSnap.data() : {};
      if (usage.monthKey !== claimedMonthKey) return;
      const scansUsed = Number(usage.scansUsed || 0);
      if (scansUsed <= 0) return;
      tx.set(useRef, {
        monthKey: claimedMonthKey,
        scansUsed: scansUsed - 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
  } catch (error) {
    console.error('Scan quota refund failed:', error.message);
  }
}

function normalizeNutrition(rawText) {
  const jsonText = extractJson(rawText);
  const decoded = JSON.parse(jsonText);
  const items = Array.isArray(decoded?.items) ? decoded.items : [decoded];
  const cleaned = items.map((item) => {
    const normalized = {
      food_name: String(item.food_name || item.foodName || 'Unknown Food').slice(0, 120),
      portion: String(item.portion || 'Standard portion').slice(0, 120),
      calories: clampInt(item.calories, 0, 5000),
      protein: clampInt(item.protein, 0, 500),
      carbs: clampInt(item.carbs, 0, 800),
      fat: clampInt(item.fat, 0, 500),
      health_score: clampInt(item.health_score ?? item.healthScore ?? 5, 0, 10),
      insights: Array.isArray(item.insights) ? item.insights.slice(0, 3).map((v) => String(v).slice(0, 40)) : [],
      alternatives: Array.isArray(item.alternatives) ? item.alternatives.slice(0, 3).map((v) => String(v).slice(0, 40)) : [],
    };
    const check = reconcileNutrition(normalized);
    normalized.nutrition_source = 'ai_estimate';
    normalized.nutrition_flag = check.ok ? 'ok' : 'inconsistent';
    normalized.atwater_ratio = check.ratio;
    if (!check.ok) {
      console.warn(
        JSON.stringify({
          event: 'nutrition.atwater_mismatch',
          pipeline: 'v1',
          food: normalized.food_name,
          stated: normalized.calories,
          ratio: check.ratio,
        })
      );
    }
    return normalized;
  });
  if (cleaned.length === 0) throw new Error('empty-nutrition-result');
  return { items: cleaned };
}

// Fraction by which the macro-derived energy may differ from the stated
// calories before an item is flagged. Deliberately generous: dietary fibre
// yields ~2 kcal/g rather than 4, and alcohol contributes 7 kcal/g without
// appearing in protein, carbs or fat at all.
const ATWATER_TOLERANCE = Number(process.env.ATWATER_TOLERANCE || 0.25);

// Checks that calories, protein, carbs and fat describe the same food.
//
// Clamping each value into a plausible range — which is all normalizeNutrition
// did — cannot catch a self-contradictory set. 400 kcal with 10g protein, 20g
// carbs and 5g fat reconciles to 165 kcal and was previously logged in silence.
function reconcileNutrition({ calories, protein, carbs, fat }) {
  const stated = Number(calories) || 0;
  const derived =
    (Number(protein) || 0) * 4 + (Number(carbs) || 0) * 4 + (Number(fat) || 0) * 9;

  // Near-zero foods (tea, black coffee, diet soda) carry rounding noise that
  // makes a ratio meaningless.
  if (stated < 25 && derived < 25) return { ok: true, ratio: null };
  if (stated <= 0) return { ok: derived < 25, ratio: null };

  const ratio = derived / stated;
  const ok =
    ratio >= 1 - ATWATER_TOLERANCE && ratio <= 1 + ATWATER_TOLERANCE;
  return { ok, ratio: Math.round(ratio * 100) / 100 };
}

function calculateNutrition(per100g, weightGrams) {
  const factor = weightGrams / 100;
  return {
    calories: Math.round(per100g.calories * factor),
    protein: Math.round((per100g.protein * factor) * 10) / 10,
    carbs: Math.round((per100g.carbs * factor) * 10) / 10,
    fat: Math.round((per100g.fat * factor) * 10) / 10,
  };
}

function enrichScanResults(foods) {
  if (!Array.isArray(foods) || foods.length === 0) {
    throw new Error('empty-food-detection');
  }

  const items = foods.map((food) => {
    const name = String(food.name || food.food_name || 'Unknown Food').slice(0, 120);
    // The display name is localised; the match key is always English. Matching
    // on the localised name failed outright for non-Latin scripts.
    const lookupName = String(food.match_key || food.matchKey || name).slice(0, 120);
    const rawWeight = Number(food.estimated_weight_g ?? food.weight_g ?? 0);
    const weightG = Number.isFinite(rawWeight) ? Math.round(Math.max(0, rawWeight)) : 0;
    const confidence = Math.min(1, Math.max(0, Number(food.confidence || 0)));

    // A missing weight is unknown, not zero. Previously nutrition was computed
    // at a silent 100g default while weight_g went out as 0, and the client
    // then recomputed every macro as per100g x 0 = 0.
    const hasWeight = weightG > 0;
    const matched = hasWeight ? nutritionProvider.lookup(lookupName) : null;
    const nutritionMatchId = matched ? matched.id : null;

    const item = {
      food_name: name,
      match_key: lookupName,
      portion: hasWeight ? `${weightG}g` : 'Unknown',
      weight_g: weightG,
      confidence: Math.round(confidence * 100) / 100,
      nutrition_match_id: nutritionMatchId,
      // The database row actually used. Without this the client cannot tell the
      // user which food the numbers describe, so "fried chicken" resolving to a
      // near-neighbour is invisible rather than correctable.
      matched_name: matched ? matched.displayName : null,
      matched: !!matched,
      nutrition_source: matched ? 'database' : 'unmatched',
    };

    if (matched) {
      const actual = calculateNutrition(matched.per100g, weightG);
      item.calories = actual.calories;
      item.protein = actual.protein;
      item.carbs = actual.carbs;
      item.fat = actual.fat;
      item.health_score = 5;
      item.insights = [];
      item.alternatives = [];
      item.nutrition = {
        per100g: { calories: matched.per100g.calories, protein: matched.per100g.protein, carbs: matched.per100g.carbs, fat: matched.per100g.fat },
        actual: actual,
      };
      // Database-derived values should always reconcile; check anyway so a bad
      // row in nutrition_db.json surfaces in logs rather than in a user's diary.
      const check = reconcileNutrition(actual);
      item.nutrition_flag = check.ok ? 'ok' : 'inconsistent';
      item.atwater_ratio = check.ratio;
      if (!check.ok) {
        console.warn(
          JSON.stringify({
            event: 'nutrition.atwater_mismatch',
            pipeline: 'v2',
            food: name,
            match_id: nutritionMatchId,
            ratio: check.ratio,
          })
        );
      }
    } else {
      unmatchedFoodLogger.logUnmatched(lookupName, {
        confidence,
        weight_g: weightG,
        display_name: name,
        reason: hasWeight ? 'no_database_match' : 'missing_weight',
      });
      item.nutrition_flag = 'unmatched';
      item.atwater_ratio = null;
      item.calories = null;
      item.protein = null;
      item.carbs = null;
      item.fat = null;
      item.health_score = 5;
      item.insights = ['Nutrition unavailable'];
      item.alternatives = [];
      item.nutrition = null;
    }

    return item;
  });

  const totals = items.reduce(
    (acc, item) => {
      if (item.nutrition && item.nutrition.actual) {
        acc.calories += item.nutrition.actual.calories;
        acc.protein += item.nutrition.actual.protein;
        acc.carbs += item.nutrition.actual.carbs;
        acc.fat += item.nutrition.actual.fat;
      }
      return acc;
    },
    { calories: 0, protein: 0, carbs: 0, fat: 0 }
  );

  totals.calories = Math.round(totals.calories);
  totals.protein = Math.round(totals.protein * 10) / 10;
  totals.carbs = Math.round(totals.carbs * 10) / 10;
  totals.fat = Math.round(totals.fat * 10) / 10;

  return { items, totals };
}

function extractJson(text) {
  const cleaned = String(text || '').replace(/```(?:json)?/gi, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  if (start < 0) {
    const preview = cleaned.length > 500 ? cleaned.slice(0, 500) + '...' : cleaned;
    throw new Error(`json-not-found: ${preview}`);
  }

  let depth = 0;
  let inString = false;
  let escaping = false;
  for (let i = start; i < cleaned.length; i++) {
    const char = cleaned[i];
    if (escaping) {
      escaping = false;
      continue;
    }
    if (char === '\\') {
      escaping = true;
      continue;
    }
    if (char === '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;
    if (char === '{') depth += 1;
    if (char === '}') {
      depth -= 1;
      if (depth === 0) return cleaned.slice(start, i + 1);
    }
  }

  const preview = cleaned.length > 500 ? cleaned.slice(0, 500) + '...' : cleaned;
  throw new Error(`json-not-found: ${preview}`);
}

function stripThink(text) {
  return String(text || '').replace(/<think>[\s\S]*?<\/think>/gi, '').replace(/<think>[\s\S]*/gi, '').trim();
}

function repairAiJson(jsonText) {
  return String(jsonText || '')
    .replace(/```(?:json)?/gi, '')
    .replace(/```/g, '')
    .trim()
    .replace(/,\s*([}\]])/g, '$1')
    .replace(/}\s*{/g, '},{')
    .replace(/]\s*{/g, '],{')
    .replace(/}\s*"/g, '},"');
}

function normalizeAiJsonText(rawText) {
  const extracted = extractJson(rawText);
  try {
    JSON.parse(extracted);
    return extracted;
  } catch (_) {
    const repaired = repairAiJson(extracted);
    JSON.parse(repaired);
    return repaired;
  }
}

function buildJsonPrompt(prompt) {
  return [
    'Return ONLY one valid JSON object. No markdown, no explanation, no code fences.',
    'Use double-quoted JSON keys and strings. Do not include trailing commas.',
    'The response must parse with JSON.parse.',
    '',
    prompt,
  ].join('\n');
}

function clampInt(value, min, max) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return min;
  return Math.max(min, Math.min(max, Math.round(parsed)));
}

// Output budget for image calls.
//
// This was 1024 (512 on Gemini). The v2 detector emits a JSON object per food,
// so a full plate ran past the cap and the reply was cut mid-key — which
// surfaced two different ways: `json-not-found` when the truncated text still
// had content, and `empty-deepseek-response` when a reasoning model spent the
// whole budget before emitting any. Both were the same bug.
const AI_IMAGE_MAX_TOKENS = Number(process.env.AI_IMAGE_MAX_TOKENS) || 4096;

async function callAiWithImage(base64Data, language, customPrompt = null, useV2 = false) {
  const systemPrompt = customPrompt || (useV2 ? getV2SystemPrompt(language) : getSystemPrompt(language));
  const maxRetries = Number(process.env.AI_RETRY_LIMIT) || 3;
  const baseDelay = Number(process.env.AI_RETRY_DELAY_MS) || 2000;

  // A 20s per-call ceiling was fine while replies were capped at 1024 tokens.
  // With a 4096 budget the model writes a full answer and runs past it, and
  // axios aborts a request that was about to succeed ('aborted' in the logs).
  const perCall = Number(process.env.AI_IMAGE_TIMEOUT_MS) || 45000;

  // And an overall deadline, because the client gives up at 60s
  // (TimeoutPolicy.aiScan). Without it, a full chain — three providers times
  // three attempts — keeps burning upstream calls long after the only caller
  // has stopped listening, and the user never sees the result it paid for.
  const deadline = Number(process.env.AI_IMAGE_DEADLINE_MS) || 50000;
  const startedAt = Date.now();
  const elapsed = () => Date.now() - startedAt;
  const outOfTime = () => elapsed() >= deadline;
  // Never wait past the deadline on a single call.
  const budget = () => Math.max(1000, Math.min(perCall, deadline - elapsed()));

  const dataUrl = `data:image/jpeg;base64,${base64Data}`;

  // One OpenAI-shaped vision request, since three of the four speak it.
  const openAiVision = async (url, model, headers) => {
    const response = await axios.post(
      url,
      {
        model,
        messages: [{
          role: 'user',
          content: [
            { type: 'text', text: systemPrompt },
            { type: 'image_url', image_url: { url: dataUrl } },
          ],
        }],
        temperature: 0.4,
        max_tokens: AI_IMAGE_MAX_TOKENS,
      },
      { headers: { ...headers, 'Content-Type': 'application/json' }, timeout: budget() },
    );
    const choice = response.data?.choices?.[0];
    const content = choice?.message?.content;
    if (content) return stripThink(content);
    // A reasoning model that spends its whole budget thinking returns an
    // empty content with finish_reason 'length'. Name it.
    throw new Error(
      `empty-response (finish_reason=${choice?.finish_reason ?? 'unknown'}, `
      + `reasoning_chars=${(choice?.message?.reasoning_content || '').length})`,
    );
  };

  // Each entry reports whether it is configured, so an absent key is a skip
  // rather than a failed leg. `attempt` only matters to Gemini, which rotates
  // across however many keys are configured.
  const providers = {
    groq: {
      key: () => process.env.GROQ_API_KEY,
      run: (key) => openAiVision(
        'https://api.groq.com/openai/v1/chat/completions',
        process.env.GROQ_VISION_MODEL || 'qwen/qwen3.6-27b',
        { Authorization: `Bearer ${key}` },
      ),
    },
    gemini: {
      key: () => (process.env.GEMINI_API_KEYS || process.env.GEMINI_API_KEY || '')
        .split(',').map(k => k.trim()).filter(Boolean),
      run: async (keys, attempt) => {
        const key = keys[(attempt - 1) % keys.length];
        const response = await axios.post(
          `https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_SCANNER_MODEL || 'gemini-3.6-flash'}:generateContent`,
          {
            contents: [{
              parts: [
                { text: systemPrompt },
                { inline_data: { mime_type: 'image/jpeg', data: base64Data } },
              ],
            }],
            generationConfig: { temperature: 0.4, maxOutputTokens: AI_IMAGE_MAX_TOKENS },
          },
          { headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key }, timeout: budget() },
        );
        const candidate = response.data?.candidates?.[0];
        const text = candidate?.content?.parts?.[0]?.text;
        if (text) return stripThink(text);
        throw new Error(`empty-response (finishReason=${candidate?.finishReason ?? 'unknown'})`);
      },
    },
    deepseek: {
      key: () => process.env.DEEPSEEK_API_KEY,
      run: (key) => openAiVision(
        'https://api.deepseek.com/chat/completions',
        process.env.DEEPSEEK_SCANNER_MODEL || 'deepseek-v4-flash-vision-exp',
        { Authorization: `Bearer ${key}` },
      ),
    },
    openrouter: {
      key: () => process.env.OPENROUTER_API_KEY || process.env.QWEN_API_KEY,
      run: (key) => openAiVision(
        'https://openrouter.ai/api/v1/chat/completions',
        process.env.SCANNER_MODEL || 'qwen/qwen3-vl-8b-instruct',
        { Authorization: `Bearer ${key}`, 'HTTP-Referer': 'https://snapcal.com', 'X-Title': 'SnapCal' },
      ),
    },
  };

  // Order is configuration, not code. Groq and Gemini lead because both are
  // fast non-reasoning models on free tiers; DeepSeek backs them up because it
  // reasons before answering, which is accurate but costs ~20s. Reorder from
  // the dashboard — AI_IMAGE_PROVIDER_ORDER=deepseek pins a single provider,
  // which is what DEEPSEEK_STRICT used to do.
  const order = (process.env.AI_IMAGE_PROVIDER_ORDER || 'groq,deepseek,gemini,openrouter')
    .split(',').map(p => p.trim().toLowerCase()).filter(p => providers[p]);

  const configured = order.filter(name => {
    const key = providers[name].key();
    return Array.isArray(key) ? key.length > 0 : Boolean(key);
  });

  if (configured.length === 0) {
    // Distinct from a provider outage on purpose: nothing was even attempted.
    throw new Error(`ai-not-configured: no key set for any of [${order.join(', ')}]`);
  }

  const failures = [];

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    for (const name of configured) {
      if (outOfTime()) break;
      // A provider that has been failing is skipped outright rather than
      // waited on. Trying it costs this scan its full timeout before falling
      // through, which during an outage is added to every user's scan.
      if (!providerAvailable(name)) {
        failures.push(`${name}: skipped (circuit open)`);
        metrics.scans.inc({ outcome: 'provider_skipped', provider: name });
        continue;
      }
      try {
        const result = await providers[name].run(providers[name].key(), attempt);
        // Which provider actually answered. Without this the only way to tell
        // is the absence of failure lines above the success, which is an
        // inference, not a fact — and it silently breaks the moment a
        // provider succeeds after another has already failed.
        console.error(
          `${name} vision scan succeeded in ${elapsed()}ms (attempt ${attempt}/${maxRetries})`,
        );
        metrics.scans.inc({ outcome: 'provider_ok', provider: name });
        recordProviderSuccess(name);
        lastImageProvider = name;
        return result;
      } catch (err) {
        const detail = err.response?.data
          ? JSON.stringify(err.response.data).slice(0, 300)
          : err.message;
        failures.push(`${name}: ${detail}`);
        metrics.scans.inc({ outcome: 'provider_error', provider: name });
        recordProviderFailure(name);
        console.error(`${name} vision scan failed (attempt ${attempt}/${maxRetries}):`, detail);
      }
    }

    if (outOfTime()) {
      console.error(`Image deadline reached after ${elapsed()}ms, giving up`);
      break;
    }

    if (attempt < maxRetries) {
      const delay = baseDelay * attempt;
      console.error(`All providers failed, retrying in ${delay}ms (attempt ${attempt}/${maxRetries})...`);
      await new Promise(r => setTimeout(r, delay));
    }
  }

  // Name what each provider actually said, so a misconfiguration is never
  // again indistinguishable from an outage.
  throw new Error(`ai-scan-failed after ${elapsed()}ms — ${failures.slice(-configured.length).join(' | ')}`);
}

/// Text generation with a real provider chain.
///
/// This used to be Gemini -> OpenRouter/Qwen and nothing else: if
/// OPENROUTER_API_KEY and QWEN_API_KEY were both unset it threw
/// `ai-not-configured` the instant Gemini hiccuped, even though GROQ_API_KEY
/// and DEEPSEEK_API_KEY were configured and perfectly usable. Every text
/// feature then returned a hard 500 with no fallback. The meal planner tripped
/// it first because it is the only caller asking for 8192 tokens of JSON.
///
/// Two behaviours worth keeping in mind:
///  - A Gemini response truncated at MAX_TOKENS has no `parts[0].text`. That
///    case used to fall through silently, logging nothing; it now logs the
///    finishReason so a truncation is distinguishable from a model error.
///  - Every leg is tried before giving up, and the thrown error names what each
///    provider actually said instead of a bare `ai-not-configured`.
async function callAiText(prompt, options = {}) {
  const requireJson = options.responseMimeType === 'application/json' || options.requireJson === true;
  const effectivePrompt = requireJson ? buildJsonPrompt(prompt) : prompt;
  const maxOutputTokens = options.maxOutputTokens || 2048;
  const temperature = requireJson ? 0.2 : (options.temperature ?? 0.7);
  const timeout = options.timeout || 25000;
  const failures = [];

  const detailOf = (err) => {
    const data = err.response?.data;
    if (!data) return err.message;
    return typeof data === 'string' ? data.slice(0, 300) : JSON.stringify(data).slice(0, 300);
  };

  // One OpenAI-shaped text request; three of the four providers speak it.
  const openAiText = async (name, url, model, key, extraHeaders) => {
    const response = await axios.post(
      url,
      {
        model,
        messages: [
          ...(requireJson ? [{ role: 'system', content: 'Return only valid JSON. No markdown. No prose.' }] : []),
          { role: 'user', content: effectivePrompt },
        ],
        max_tokens: maxOutputTokens,
        temperature,
        ...(requireJson ? { response_format: { type: 'json_object' } } : {}),
      },
      {
        headers: {
          Authorization: `Bearer ${key}`,
          'Content-Type': 'application/json',
          ...(extraHeaders || {}),
        },
        timeout,
      },
    );
    const content = response.data?.choices?.[0]?.message?.content;
    const cleaned = content ? stripThink(content) : '';
    if (cleaned) return requireJson ? normalizeAiJsonText(cleaned) : cleaned;
    throw new Error(`empty-response (model=${model})`);
  };

  const providers = {
    deepseek: {
      key: () => process.env.DEEPSEEK_API_KEY,
      run: (key) => openAiText(
        'deepseek',
        'https://api.deepseek.com/chat/completions',
        process.env.DEEPSEEK_TEXT_MODEL || 'deepseek-chat',
        key,
      ),
    },
    gemini: {
      key: () => process.env.GEMINI_API_KEY,
      run: async (key) => {
        const response = await axios.post(
          `https://generativelanguage.googleapis.com/v1beta/models/${options.model || process.env.GEMINI_TEXT_MODEL || 'gemini-3.6-flash'}:generateContent`,
          {
            contents: [{ parts: [{ text: effectivePrompt }] }],
            generationConfig: {
              temperature,
              maxOutputTokens,
              ...(options.responseMimeType ? { responseMimeType: options.responseMimeType } : {}),
            },
          },
          { headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key }, timeout },
        );
        const candidate = response.data?.candidates?.[0];
        const text = candidate?.content?.parts?.[0]?.text;
        if (text) return requireJson ? normalizeAiJsonText(text) : text;
        // A response truncated at maxOutputTokens carries no parts[0].text.
        // Naming the reason keeps a truncation distinguishable from a refusal.
        const reason = candidate?.finishReason
          || response.data?.promptFeedback?.blockReason
          || 'no-text-in-response';
        throw new Error(`${reason} (maxOutputTokens=${maxOutputTokens})`);
      },
    },
    groq: {
      key: () => process.env.GROQ_API_KEY,
      run: (key) => openAiText(
        'groq',
        'https://api.groq.com/openai/v1/chat/completions',
        options.groqTextModel || process.env.GROQ_TEXT_MODEL || 'openai/gpt-oss-120b',
        key,
      ),
    },
    openrouter: {
      key: () => process.env.OPENROUTER_API_KEY || process.env.QWEN_API_KEY,
      run: (key) => openAiText(
        'openrouter',
        'https://openrouter.ai/api/v1/chat/completions',
        options.textModel || process.env.TEXT_MODEL || 'qwen/qwen-plus',
        key,
        { 'HTTP-Referer': 'https://snapcal.com', 'X-Title': 'SnapCal' },
      ),
    },
  };

  // Gemini used to be hardcoded ahead of the fallback array, so it could not be
  // reordered without a deploy. Order is configuration here, as it is for
  // images — though the two chains are deliberately separate: the coach and
  // planner want a strong writer, the scanner wants speed.
  const order = (options.providerOrder || process.env.AI_TEXT_PROVIDER_ORDER || 'deepseek,gemini,groq,openrouter')
    .split(',').map(p => p.trim().toLowerCase()).filter(p => providers[p]);

  const configured = order.filter(name => Boolean(providers[name].key()));
  if (configured.length === 0) {
    throw new Error(`ai-not-configured: no key set for any of [${order.join(', ')}]`);
  }

  for (const name of configured) {
    try {
      const result = await providers[name].run(providers[name].key());
      console.error(`${name} text succeeded (model tier: ${name})`);
      return result;
    } catch (err) {
      const detail = detailOf(err);
      console.error(`${name} text failed:`, detail);
      failures.push(`${name}:${detail}`);
    }
  }

  throw new Error(`ai-text-unavailable: ${failures.join(' | ')}`);
}

// Retention, expressed as a field Firestore's TTL service deletes on.
//
// Both of these collections grow forever and are never queried by the app.
// Without a bound they become the largest thing in the database: the cost is
// storage you keep paying for, and exports and restores that take longer every
// month for data nobody reads.
//
// Firestore deletes a document within ~24h of the timestamp in its TTL field.
// The policies themselves are declared in firestore.indexes.json and must be
// deployed (`firebase deploy --only firestore:indexes`) for these fields to do
// anything -- writing the field without the policy just stores a date.
const AUDIT_LOG_RETENTION_DAYS = Number(process.env.AUDIT_LOG_RETENTION_DAYS || 365);
// Comfortably longer than any webhook retry window, since this collection IS
// the idempotency guard: expiring an event id early would let a replayed
// webhook be processed twice.
const REVENUECAT_EVENT_RETENTION_DAYS = Number(process.env.REVENUECAT_EVENT_RETENTION_DAYS || 90);

function retentionDeadline(days) {
  return admin.firestore.Timestamp.fromMillis(Date.now() + days * 24 * 60 * 60 * 1000);
}

function eventRetentionDeadline() {
  return retentionDeadline(REVENUECAT_EVENT_RETENTION_DAYS);
}

/// Whether a stored path belongs to this user's scan.
///
/// Accepts the legacy `users/{uid}/scans/...` layout as well as the current
/// `scans/{uid}/...` one, so scans uploaded before the prefix change stay
/// processable and deletable. Drop the legacy branch once nothing older than
/// the storage retention window remains.
function isOwnedScanPath(storagePath, uid, scanId) {
  return (
    storagePath.startsWith(`scans/${uid}/${scanId}/`) ||
    storagePath.startsWith(`users/${uid}/scans/${scanId}/`)
  );
}

async function writeAuditLog({ actorUid, action, targetUid, result, metadata = {} }) {
  await db.collection('auditLogs').add({
    actorUid,
    action,
    targetUid,
    result,
    metadata,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: retentionDeadline(AUDIT_LOG_RETENTION_DAYS),
  });
  metrics.firestoreOps.inc({ operation: 'create', collection: 'auditLogs' });
}

app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'SnapCal Backend' });
});

// Rolling record of recent scan outcomes.
//
// The previous /health returned a hardcoded 'ok'. It proved Node was running,
// which was never the question — it reported perfect health throughout a period
// when every single scan was failing, which is why a total outage of the app's
// core feature was found by a human trying it rather than by a monitor.
// Set the moment a shutdown signal arrives, so /health starts failing and the
// load balancer stops sending new work here before the listener closes.
let isShuttingDown = false;

const SCAN_WINDOW = Number(process.env.HEALTH_WINDOW) || 20;
const scanOutcomes = [];
let lastScanError = null;
let lastScanSuccessAt = null;

// Which provider answered the most recent scan, for the outcome metric. Best
// effort and per-process: it labels a counter, it is not load-bearing.
let lastImageProvider = 'unknown';

function recordScan(ok, detail, seconds = null) {
  metrics.scans.inc({
    outcome: ok ? 'success' : 'failure',
    provider: ok ? lastImageProvider : 'none',
  });
  if (seconds !== null) {
    metrics.scanDuration.observe({ outcome: ok ? 'success' : 'failure' }, seconds);
  }
  scanOutcomes.push(ok);
  if (scanOutcomes.length > SCAN_WINDOW) scanOutcomes.shift();
  if (ok) {
    lastScanSuccessAt = new Date().toISOString();
  } else {
    lastScanError = { at: new Date().toISOString(), detail: String(detail || '').slice(0, 300) };
  }
}

app.get('/health', (req, res) => {
  const attempts = scanOutcomes.length;
  const failures = scanOutcomes.filter(ok => !ok).length;
  const failureRate = attempts > 0 ? failures / attempts : 0;

  // Which providers could serve a scan. Names and booleans only — never keys.
  const providerKeys = {
    groq: Boolean(process.env.GROQ_API_KEY),
    gemini: Boolean(process.env.GEMINI_API_KEYS || process.env.GEMINI_API_KEY),
    deepseek: Boolean(process.env.DEEPSEEK_API_KEY),
    openrouter: Boolean(process.env.OPENROUTER_API_KEY || process.env.QWEN_API_KEY),
  };
  const configured = Object.entries(providerKeys).filter(([, v]) => v).map(([k]) => k);

  // Unhealthy on a sustained failure rate, or with nothing able to serve a
  // scan at all. A monitor watching for non-200 pages you on either — which is
  // the whole point of the endpoint.
  const threshold = Number(process.env.HEALTH_FAIL_THRESHOLD) || 0.5;
  const degraded = configured.length === 0 || (attempts >= 3 && failureRate > threshold);

  // Draining reports 503 too, but says so distinctly: an operator reading this
  // during a deploy should see a planned shutdown, not a provider outage.
  if (isShuttingDown) {
    return res.status(503).json({
      status: 'shutting_down',
      timestamp: new Date().toISOString(),
    });
  }

  res.status(degraded ? 503 : 200).json({
    status: degraded ? 'degraded' : 'ok',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.round(process.uptime()),
    scan: {
      pipeline: (process.env.SCAN_PIPELINE || SCAN_PIPELINE),
      recentAttempts: attempts,
      recentFailures: failures,
      failureRate: Number(failureRate.toFixed(2)),
      lastSuccessAt: lastScanSuccessAt,
      lastError: lastScanError,
    },
    providers: {
      order: (process.env.AI_IMAGE_PROVIDER_ORDER || 'groq,deepseek,gemini,openrouter').split(',').map(p => p.trim()),
      configured,
      // Any provider reading 'open' is currently being skipped.
      breakers: breakerStates(),
    },
    concurrency: scanConcurrency(),
    // Booleans only, never the secrets themselves. If both of these read
    // false the server has no way to find out that anyone paid: the webhook
    // is the fast path, the REST key is the fallback, and without either a
    // paying user stays free forever. That failure is completely silent --
    // nobody reports it, they just ask for a refund -- so it belongs
    // somewhere you can see it without opening a dashboard.
    billing: {
      webhookConfigured: Boolean(REVENUECAT_WEBHOOK_AUTH),
      restVerificationConfigured: Boolean(REVENUECAT_SECRET_API_KEY),
    },
  });
});

/// Prometheus scrape target.
///
/// Guarded by a bearer token rather than left open: the series names and label
/// values describe traffic shape, provider health and quota pressure, which is
/// reconnaissance for anyone deciding what to attack. Set METRICS_TOKEN and
/// give it to the scraper. Unset in production means the endpoint is off, not
/// public — failing open on an observability endpoint is how internal metrics
/// end up indexed.
app.get('/metrics', (req, res) => {
  const token = process.env.METRICS_TOKEN || '';
  if (!token) {
    return res.status(404).json({ error: 'Not found.' });
  }
  const presented = (req.headers.authorization || '').replace(/^Bearer /, '');
  const a = Buffer.from(presented);
  const b = Buffer.from(token);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    return res.status(401).json({ error: 'Unauthorized.' });
  }
  res.set('Content-Type', 'text/plain; version=0.0.4; charset=utf-8');
  return res.status(200).send(renderMetrics());
});

app.use('/api', apiLimiter);

app.post('/api/food-scans', scanLimiter, authenticateToken, verifyAppCheck, async (req, res) => {
  const uid = req.user.uid;
  const { scanId, fileName, contentType, inputSource = 'camera', language = 'en' } = req.body || {};

  if (!isSafeId(scanId) || !isSafeFileName(fileName)) {
    return safeError(res, 400, 'Invalid scan request.');
  }
  if (contentType !== 'image/jpeg' && contentType !== 'image/png' && contentType !== 'image/webp') {
    return safeError(res, 400, 'Unsupported image type.');
  }
  if (!['camera', 'gallery'].includes(inputSource)) {
    return safeError(res, 400, 'Invalid scan source.');
  }

  // Top-level `scans/` prefix, not `users/{uid}/scans/`.
  //
  // A GCS lifecycle rule matches on an object-name PREFIX and cannot wildcard a
  // path segment, so a uid in the middle makes the scan images unreachable by
  // any retention policy -- they would grow forever while progress photos, which
  // must be kept, sit under the same `users/` prefix and would be caught by any
  // rule broad enough to match. Putting scans under their own root makes the
  // 30-day rule a one-liner and keeps it away from anything the user owns
  // long-term. The uid is still the second segment, so the rules stay
  // owner-scoped exactly as before.
  const storagePath = `scans/${uid}/${scanId}/${fileName}`;
  try {
    await scanDoc(uid, scanId).set({
      storagePath,
      contentType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'uploaded',
      inputSource,
      language: cleanLanguage(language),
    }, { merge: false });
    await userDoc(uid).collection('uploads').doc(scanId).set({
      storagePath,
      contentType,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      scanId,
      status: 'uploaded',
    });
    return res.status(201).json({ scanId, storagePath, status: 'uploaded' });
  } catch (error) {
    console.error('Create scan failed:', error.message);
    return safeError(res, 500, 'Could not create scan.');
  }
});

app.post('/api/food-scans/:scanId/process', scanLimiter, authenticateToken, verifyAppCheck, async (req, res) => {
  const uid = req.user.uid;
  const { scanId } = req.params;
  if (!isSafeId(scanId)) return safeError(res, 404, 'Scan not found.');

  let scan;
  try {
    scan = await claimScanQuota(uid, scanId);
  } catch (error) {
    if (error.code === 402) {
      metrics.quotaDenials.inc({ kind: 'scan' });
      return safeError(res, 402, 'Scan limit reached.');
    }
    if (error.code === 409) return safeError(res, 409, 'Scan is already processing.');
    return safeError(res, 404, 'Scan not found.');
  }

  try {
    const storagePath = scan.storagePath;
    if (!storagePath || !isOwnedScanPath(storagePath, uid, scanId)) {
      throw new Error('invalid-storage-path');
    }

    const file = admin.storage().bucket().file(storagePath);
    const [metadata] = await file.getMetadata();
    const size = Number(metadata.size || 0);
    const contentType = metadata.contentType || scan.contentType || '';
    if (size <= 0 || size > MAX_IMAGE_BYTES || !contentType.startsWith('image/')) {
      throw new Error('invalid-upload');
    }

    const [bytes] = await file.download();
    const raw = await callAiWithImage(bytes.toString('base64'), cleanLanguage(scan.language));
    const nutrition = normalizeNutrition(raw);
    const totals = nutrition.items.reduce((acc, item) => ({
      calories: acc.calories + item.calories,
      protein: acc.protein + item.protein,
      carbs: acc.carbs + item.carbs,
      fat: acc.fat + item.fat,
    }), { calories: 0, protein: 0, carbs: 0, fat: 0 });

    await scanDoc(uid, scanId).set({
      status: 'completed',
      serverNutritionResult: nutrition,
      serverCalories: totals.calories,
      serverProtein: totals.protein,
      serverCarbs: totals.carbs,
      serverFat: totals.fat,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return res.status(200).json({ scanId, status: 'completed', ...nutrition });
  } catch (error) {
    console.error('Process scan failed:', error.message);
    await scanDoc(uid, scanId).set({
      status: 'failed',
      processingError: 'Scan processing failed.',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return safeError(res, 500, 'Scan processing failed.');
  }
});

app.delete('/api/food-scans/:scanId', authenticateToken, verifyAppCheck, async (req, res) => {
  const uid = req.user.uid;
  const { scanId } = req.params;
  if (!isSafeId(scanId)) return safeError(res, 404, 'Scan not found.');

  const ref = scanDoc(uid, scanId);
  const snap = await ref.get();
  if (!snap.exists) return safeError(res, 404, 'Scan not found.');

  const storagePath = snap.data().storagePath;
  if (storagePath && isOwnedScanPath(storagePath, uid, scanId)) {
    await admin.storage().bucket().file(storagePath).delete({ ignoreNotFound: true });
  }
  await ref.delete();
  await userDoc(uid).collection('uploads').doc(scanId).delete().catch(() => {});
  return res.status(204).send();
});

app.get('/api/premium-status', authenticateToken, verifyAppCheck, async (req, res) => {
  const status = await getPremiumStatus(req.user.uid);
  return res.status(200).json(status);
});

/// Records a bonus scan earned by watching a rewarded ad.
///
/// The client used to grant these to itself in SharedPreferences while the
/// server knew nothing about them, so the scan the user had just earned came
/// back 402. The count lives here now, which is the only place that can
/// actually enforce it.
///
/// What this does and does not prove: App Check establishes that the call came
/// from a genuine build of the app, and auth establishes who. Neither proves
/// an ad was really watched -- that would need AdMob's server-side
/// verification callback, which is a larger piece of work. The monthly cap is
/// what bounds the damage in the meantime: the worst a determined user gets is
/// MAX_BONUS_SCANS_PER_MONTH free scans, which is roughly what they would get
/// by watching the ads honestly.
app.post('/api/scans/bonus', apiLimiter, authenticateToken, verifyAppCheck, async (req, res) => {
  const uid = req.user.uid;
  try {
    const result = await db.runTransaction(async (tx) => {
      const useRef = usageDoc(uid);
      const useSnap = await tx.get(useRef);
      const usage = useSnap.exists ? useSnap.data() : {};
      const monthKey = currentMonthKey();
      const current = bonusScansFor(usage, monthKey);

      if (current >= MAX_BONUS_SCANS_PER_MONTH) {
        return { granted: false, bonusScans: current, monthKey, usage };
      }

      // Writing monthKey here also rolls the month over for a user whose
      // first action this month is watching an ad: scansUsed is stamped with
      // last month's key, so it has to reset alongside the bonus or they
      // would inherit last month's usage against this month's allowance.
      const rolledOver = usage.monthKey !== monthKey;
      tx.set(useRef, {
        monthKey,
        bonusScans: current + 1,
        ...(rolledOver ? { scansUsed: 0, premiumScansUsed: 0 } : {}),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      return {
        granted: true,
        bonusScans: current + 1,
        monthKey,
        usage: rolledOver ? { monthKey, scansUsed: 0 } : usage,
      };
    });

    metrics.firestoreOps.inc({ operation: 'set', collection: 'usage' });

    const scansUsed =
      result.usage && result.usage.monthKey === result.monthKey
        ? Number(result.usage.scansUsed || 0)
        : 0;
    const scanAllowance = FREE_MONTHLY_SCANS + result.bonusScans;

    return res.status(200).json({
      granted: result.granted,
      bonusScans: result.bonusScans,
      maxBonusScansPerMonth: MAX_BONUS_SCANS_PER_MONTH,
      scanAllowance,
      scansRemaining: Math.max(0, scanAllowance - scansUsed),
    });
  } catch (error) {
    console.error('Bonus scan grant failed:', error.message);
    return safeError(res, 500, 'Could not record the bonus scan.');
  }
});

app.post('/api/ai/text', authenticateToken, verifyAppCheck, async (req, res) => {
  const body = req.body || {};
  if (!assertPlainObject(body) || typeof body.prompt !== 'string' || body.prompt.length < 1 || body.prompt.length > 12000) {
    return safeError(res, 400, 'Invalid AI request.');
  }

  // Only the coach is rate-limited. This endpoint also serves planner,
  // insight and report generation, which are free-tier features -- gating the
  // whole endpoint would break them.
  if (body.purpose === 'coach') {
    try {
      await claimAiMessageQuota(req.user.uid);
    } catch (error) {
      if (error.code === 402) {
        metrics.quotaDenials.inc({ kind: 'ai_coach' });
        return safeError(res, 402, 'Daily AI coach limit reached. Upgrade to Pro for unlimited coaching.');
      }
      console.error('AI quota claim failed:', error.message);
      return safeError(res, 500, 'AI request failed.');
    }
  }

  try {
    const text = await callAiText(body.prompt, {
      maxOutputTokens: Math.min(Number(body.maxOutputTokens || 2048), 8192),
      responseMimeType: body.responseMimeType === 'application/json' ? 'application/json' : undefined,
      requireJson: body.responseMimeType === 'application/json',
      temperature: typeof body.temperature === 'number' ? body.temperature : 0.7,
      timeout: Math.min(Number(body.timeoutMs || 25000), 55000),
    });
    return res.status(200).json({ text });
  } catch (error) {
    // TEMPORARY DEBUG: the failure chain (which provider failed and why) is
    // included in the response so the client logcat names the root cause.
    // Remove once the coach's provider config is verified.
    console.error('AI text request failed:', error.message);
    return res.status(500).json({
      error: 'AI request failed.',
      detail: String(error.message || 'unknown').slice(0, 400),
    });
  }
});

app.post('/api/ai/image', authenticateToken, verifyAppCheck, async (req, res) => {
  const body = req.body || {};
  if (!assertPlainObject(body) || typeof body.prompt !== 'string' || typeof body.image !== 'string') {
    return safeError(res, 400, 'Invalid AI image request.');
  }

  try {
    const text = await callAiWithImage(body.image, cleanLanguage(body.language || 'en'), body.prompt);
    return res.status(200).json({ text });
  } catch (error) {
    console.error('AI image request failed:', error.message);
    return safeError(res, 500, 'AI image request failed.');
  }
});

app.post('/api/revenuecat/webhook', webhookLimiter, async (req, res) => {
  if (!REVENUECAT_WEBHOOK_AUTH) {
    return safeError(res, 503, 'Webhook not configured.');
  }
  if (!safeCompare(req.header('Authorization'), REVENUECAT_WEBHOOK_AUTH)) {
    metrics.authFailures.inc({ control: 'webhook_secret' });
    return safeError(res, 401, 'Unauthorized webhook.');
  }

  const event = req.body?.event;
  if (!assertPlainObject(event)) return safeError(res, 400, 'Invalid webhook.');

  const eventId = String(event.id || crypto.createHash('sha256').update(JSON.stringify(event)).digest('hex'));
  const appUserId = String(event.app_user_id || event.original_app_user_id || '');
  if (!isSafeId(appUserId)) return safeError(res, 400, 'Invalid webhook user.');

  const eventRef = db.collection('revenueCatEvents').doc(eventId);
  // Which users' cached entitlement this event makes stale. A TRANSFER changes
  // two accounts, not one.
  const touchedUids = new Set();
  try {
    await db.runTransaction(async (tx) => {
      const eventSnap = await tx.get(eventRef);
      if (eventSnap.exists) return;

      const type = String(event.type || '');
      const expirationMs = Number(event.expiration_at_ms || 0);

      // A TRANSFER moves an entitlement between app user IDs; treating it as
      // an expiry would deactivate the *receiving* account (BUG-019).
      if (type === 'TRANSFER') {
        const sources = (Array.isArray(event.transferred_from)
          ? event.transferred_from
          : [event.transferred_from]
        ).map((v) => String(v || '')).filter((v) => v && v !== appUserId && isSafeId(v));
        const destinations = (Array.isArray(event.transferred_to)
          ? event.transferred_to
          : [appUserId]
        ).map((v) => String(v || '')).filter(Boolean);

        for (const source of sources) {
          tx.set(subscriptionDoc(source), {
            isActive: false,
            lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            source: 'revenuecat_webhook',
            lastEventType: type,
            updatedByServer: true,
          }, { merge: true });
        }

        for (const destination of destinations) {
          if (!isSafeId(destination)) continue;
          const active = expirationMs === 0 || expirationMs > Date.now();
          tx.set(subscriptionDoc(destination), {
            entitlementId: event.entitlement_id || event.entitlement_ids?.[0] || 'pro',
            isActive: active,
            productId: event.product_id || null,
            expiresAt: expirationMs ? admin.firestore.Timestamp.fromMillis(expirationMs) : null,
            lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            source: 'revenuecat_webhook',
            revenueCatAppUserId: destination,
            updatedByServer: true,
            lastEventType: type,
          }, { merge: true });
        }

        tx.set(eventRef, {
          appUserId,
          transferredFrom: sources,
          transferredTo: destinations,
          type,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: eventRetentionDeadline(),
          processed: true,
        });
        sources.forEach((uid) => touchedUids.add(uid));
        destinations.forEach((uid) => touchedUids.add(uid));
        return;
      }

      // Only these end access before the period the user already paid for.
      // CANCELLATION means auto-renew was turned off -- access continues until
      // expiration_at_ms. PRODUCT_CHANGE is a plan switch on an active
      // subscription. BILLING_ISSUE opens the store grace period. Treating any
      // of those as a revocation deactivates a paying customer (BUG-021).
      const isActive =
        !REVOKES_ACCESS_IMMEDIATELY.includes(type) &&
        (expirationMs === 0 || expirationMs > Date.now());

      tx.set(subscriptionDoc(appUserId), {
        entitlementId: event.entitlement_id || event.entitlement_ids?.[0] || 'pro',
        isActive,
        productId: event.product_id || null,
        expiresAt: expirationMs ? admin.firestore.Timestamp.fromMillis(expirationMs) : null,
        lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        source: 'revenuecat_webhook',
        revenueCatAppUserId: appUserId,
        updatedByServer: true,
        lastEventType: type,
      }, { merge: true });

      tx.set(eventRef, {
        appUserId,
        type,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: eventRetentionDeadline(),
        processed: true,
      });
      touchedUids.add(appUserId);
    });

    // After the commit, never inside it: a transaction can be retried, and
    // invalidating a cache for a write that then rolls back re-reads Firestore
    // for nothing. Entitlement just changed for these users, so the cached
    // answer is wrong now rather than in sixty seconds.
    await Promise.all([...touchedUids].map(invalidateEntitlement));
    return res.status(200).json({ ok: true });
  } catch (error) {
    console.error('RevenueCat webhook failed:', error.message);
    return safeError(res, 500, 'Webhook processing failed.');
  }
});

app.get('/api/admin/users/:uid/summary', authenticateToken, verifyAppCheck, requireFreshAuth, requireAdmin, async (req, res) => {
  const targetUid = req.params.uid;
  if (!isSafeId(targetUid)) return safeError(res, 404, 'User not found.');

  const [userSnap, subSnap, usageSnap] = await Promise.all([
    userDoc(targetUid).get(),
    subscriptionDoc(targetUid).get(),
    usageDoc(targetUid).get(),
  ]);
  await writeAuditLog({
    actorUid: req.user.uid,
    action: 'adminGetUserSummary',
    targetUid,
    result: 'success',
  });
  return res.status(200).json({
    uid: targetUid,
    profile: userSnap.exists ? userSnap.data() : null,
    subscription: subSnap.exists ? subSnap.data() : null,
    usage: usageSnap.exists ? usageSnap.data() : null,
  });
});

app.post('/api/admin/users/:uid/access', authenticateToken, verifyAppCheck, requireFreshAuth, requireAdmin, async (req, res) => {
  const targetUid = req.params.uid;
  const { isActive, entitlementId = 'pro', productId = 'manual_grant', reason } = req.body || {};
  if (!isSafeId(targetUid) || typeof isActive !== 'boolean' || typeof reason !== 'string' || reason.trim().length < 5) {
    return safeError(res, 400, 'Invalid admin access update.');
  }

  await subscriptionDoc(targetUid).set({
    entitlementId,
    isActive,
    productId,
    expiresAt: null,
    lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    source: 'manual_admin',
    revenueCatAppUserId: targetUid,
    updatedByServer: true,
  }, { merge: true });
  await invalidateEntitlement(targetUid);
  await writeAuditLog({
    actorUid: req.user.uid,
    action: 'adminUpdateUserAccess',
    targetUid,
    result: 'success',
    metadata: { isActive, reason: reason.trim().slice(0, 500) },
  });
  return res.status(200).json({ ok: true });
});

// ── Scan Endpoint (v1 + v2) ────────────────────────────────────
// Accepts base64 image, validates auth, calls AI, returns nutrition.
// SCAN_PIPELINE env var controls which pipeline is used:
//   v1 = AI generates nutrition directly (legacy)
//   v2 = AI detects foods only, backend calculates nutrition from DB
// No image is stored anywhere — processed in memory only.
/// Sheds scan load past what one instance can hold, instead of accepting it.
///
/// Every scan holds a socket for up to 50 seconds. Past the ceiling, taking
/// one more request does not serve that user -- it slows down everyone already
/// waiting, including the cheap requests sharing the event loop. A fast 503
/// with Retry-After lets the load balancer place the work on another instance
/// and tells the client to come back, which is a far better experience than a
/// spinner that fails a minute later.
function limitScanConcurrency(req, res, next) {
  if (!tryAcquireScanSlot()) {
    const { inFlight, limit } = scanConcurrency();
    console.warn(`Scan shed: ${inFlight}/${limit} slots in use`);
    metrics.scans.inc({ outcome: 'shed', provider: 'none' });
    res.set('Retry-After', '5');
    return safeError(res, 503, 'Busy right now. Please try again in a moment.');
  }
  // release on 'close', not 'finish': a client that hangs up mid-scan must
  // free its slot too, or the ceiling ratchets down to zero over time.
  let released = false;
  const release = () => {
    if (released) return;
    released = true;
    releaseScanSlot();
  };
  res.on('finish', release);
  res.on('close', release);
  return next();
}

app.post('/v1/scan', scanLimiter, limitScanConcurrency, authenticateToken, verifyAppCheck, async (req, res) => {
  const scanStartedAt = process.hrtime.bigint();
  const scanSeconds = () => Number(process.hrtime.bigint() - scanStartedAt) / 1e9;
  const { image, language = 'en' } = req.body || {};
  const hasAuth = !!req.headers.authorization;
  const hasImage = !!image && typeof image === 'string';
  console.log(
    JSON.stringify({
      event: 'scan.request',
      method: 'POST',
      path: '/v1/scan',
      pipeline: SCAN_PIPELINE,
      authPresent: hasAuth,
      imagePresent: hasImage,
      imageSize: hasImage ? Buffer.byteLength(image, 'utf8') : 0,
    })
  );

  if (!hasImage) {
    return safeError(res, 400, 'Missing image field (base64 string).');
  }
  const imageBytes = Buffer.from(image, 'base64');
  if (imageBytes.length > MAX_IMAGE_BYTES) {
    return safeError(res, 413, 'Image too large (max 10 MB).');
  }

  const uid = req.user.uid;

  // Claim quota transactionally BEFORE calling the model (BUG-011).
  let claim;
  try {
    claim = await claimScanQuotaForScan(uid);
  } catch (error) {
    if (error.code === 402) {
      return safeError(res, 402, 'Scan limit reached.');
    }
    console.error('Scan quota claim failed:', error.message);
    return safeError(res, 500, 'Could not start scan.');
  }

  try {
    const pipeline = (req.query.pipeline || SCAN_PIPELINE).toLowerCase();

    if (pipeline === 'v2') {
      const raw = await callAiWithImage(image, cleanLanguage(language), null, true);
      const detection = JSON.parse(extractJson(raw));
      const foods = Array.isArray(detection?.foods) ? detection.foods : [];
      if (foods.length === 0) {
        return res.status(200).json({ items: [], totals: { calories: 0, protein: 0, carbs: 0, fat: 0 } });
      }
      const result = enrichScanResults(foods);

      recordScan(true, null, scanSeconds());
      console.log(JSON.stringify({ event: 'scan.success.v2', pipeline: 'v2', status: 200 }));
      const matchedCount = result.items.filter(i => i.matched).length;
      console.error(`Scan v2: ${result.items.length} foods (${matchedCount} matched, ${result.items.length - matchedCount} unmatched)`);

      return res.status(200).json({ items: result.items, totals: result.totals });
    }

    // v1 pipeline (default)
    const raw = await callAiWithImage(image, cleanLanguage(language));
    const nutrition = normalizeNutrition(raw);
    const totals = nutrition.items.reduce((acc, item) => ({
      calories: acc.calories + item.calories,
      protein: acc.protein + item.protein,
      carbs: acc.carbs + item.carbs,
      fat: acc.fat + item.fat,
    }), { calories: 0, protein: 0, carbs: 0, fat: 0 });

    recordScan(true, null, scanSeconds());
    console.log(JSON.stringify({ event: 'scan.success', pipeline: 'v1', status: 200 }));
    console.error('Scan items:', JSON.stringify(nutrition.items.map(i => ({ food_name: i.food_name, calories: i.calories }))));

    return res.status(200).json({ items: nutrition.items, totals });
  } catch (error) {
    // The quota was consumed up-front; give it back when the scan itself
    // failed so users are not charged for our provider outages.
    recordScan(false, error.message, scanSeconds());
    await refundScanQuota(uid, claim.monthKey);
    console.error(
      JSON.stringify({ event: 'scan.error', status: 502, error: error.message })
    );
    return safeError(res, 502, 'AI analysis failed. Please try again.');
  }
});

// ── Debug routes (non-production) ──────────────────────────────
if (process.env.NODE_ENV !== 'production') {
  const routeTable = [
    { method: 'GET', path: '/' },
    { method: 'GET', path: '/health' },
    { method: 'POST', path: '/v1/scan' },
    { method: 'POST', path: '/api/food-scans' },
    { method: 'POST', path: '/api/food-scans/:scanId/process' },
    { method: 'DELETE', path: '/api/food-scans/:scanId' },
    { method: 'GET', path: '/api/premium-status' },
    { method: 'POST', path: '/api/ai/text' },
    { method: 'POST', path: '/api/ai/image' },
    { method: 'POST', path: '/api/scans/bonus' },
    { method: 'POST', path: '/api/revenuecat/webhook' },
    { method: 'GET', path: '/api/admin/users/:uid/summary' },
    { method: 'POST', path: '/api/admin/users/:uid/access' },
    { method: 'POST', path: '/api/notifications/food-reminder/register' },
    { method: 'POST', path: '/api/notifications/food-reminder/trigger' },
    { method: 'POST', path: '/api/debug/grant-premium' },
    { method: 'POST', path: '/api/debug/revoke-premium' },
  ];

  app.get('/debug/routes', (req, res) => {
    res.json({ routes: routeTable });
  });
}

// ── Debug endpoints ────────────────────────────────────────────
// Never reachable in production, and admin + App Check gated regardless
// (BUG-001). Audit production `subscription/current` documents for
// source: 'debug' — any that exist are already-granted free Pro accounts.
if (NODE_ENV !== 'production') {
  app.post(
    '/api/debug/grant-premium',
    authenticateToken,
    verifyAppCheck,
    requireAdmin,
    async (req, res) => {
      await subscriptionDoc(req.user.uid).set({
        entitlementId: 'pro',
        isActive: true,
        productId: 'debug_manual_grant',
        source: 'debug',
        lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      await invalidateEntitlement(req.user.uid);
      console.log(`Debug: granted premium to ${req.user.uid}`);
      return res.json({ ok: true, uid: req.user.uid });
    },
  );

  app.post(
    '/api/debug/revoke-premium',
    authenticateToken,
    verifyAppCheck,
    requireAdmin,
    async (req, res) => {
      await subscriptionDoc(req.user.uid).set({
        isActive: false,
        lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      await invalidateEntitlement(req.user.uid);
      console.log(`Debug: revoked premium from ${req.user.uid}`);
      return res.json({ ok: true, uid: req.user.uid });
    },
  );
}

app.use((err, req, res, next) => {
  if (err?.type === 'entity.too.large') {
    return safeError(res, 413, 'Request body too large.');
  }
  console.error('Unhandled server error:', err.stack || err.message);
  return safeError(res, 500, 'Internal server error.');
});

app.post('/api/notifications/food-reminder/register', authenticateToken, verifyAppCheck, async (req, res) => {
  const { fcmToken, enabled } = req.body || {};
  const uid = req.user.uid;

  if (typeof enabled !== 'boolean') {
    return safeError(res, 400, 'Missing enabled flag.');
  }

  try {
    const settingsRef = userDoc(uid).collection('settings').doc('app');
    const payload = {
      foodRemindersEnabled: enabled,
      fcmToken: fcmToken || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // The reminder fan-out is a range query on serverReminderSentOn, and
    // Firestore excludes documents that lack the field entirely from a range
    // query. Without seeding it here, a user who has never been reminded
    // could never BE reminded — they would be invisible to the query forever.
    //
    // Server-owned field, named so that no released client writes it. See the
    // comment on eligibleUserPages() for why that naming matters.
    const existing = await settingsRef.get();
    if (!existing.exists || existing.get('serverReminderSentOn') === undefined) {
      payload.serverReminderSentOn = '1970-01-01';
    }

    await settingsRef.set(payload, { merge: true });
    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Food reminder register failed:', err.message);
    return safeError(res, 500, 'Could not register food reminder preference.');
  }
});

/// Lets Cloud Scheduler drive the fan-out without a Firebase identity.
///
/// A scheduler has no ID token and no App Check attestation, so requiring them
/// forced the cron to live inside the API process — which is what caused
/// duplicate notifications once there was more than one instance. A constant
/// -time shared-secret comparison is the standard shape for this, and the
/// route stays admin-only for human callers.
function allowSchedulerOrAdmin(req, res, next) {
  const secret = process.env.SCHEDULER_SECRET || '';
  const presented = req.get('X-Scheduler-Secret') || '';
  if (secret && presented) {
    const a = Buffer.from(secret);
    const b = Buffer.from(presented);
    if (a.length === b.length && crypto.timingSafeEqual(a, b)) {
      req.schedulerAuthenticated = true;
      return next();
    }
    return safeError(res, 401, 'Unauthorized.');
  }
  return authenticateToken(req, res, () =>
    verifyAppCheck(req, res, () => requireAdmin(req, res, next)),
  );
}

// Runs the reminder fan-out. Driven by Cloud Scheduler in production; an admin
// can still call it by hand for a manual run (BUG-018).
app.post(
  '/api/notifications/food-reminder/trigger',
  allowSchedulerOrAdmin,
  async (req, res) => {
    const { processReminders: trigger } = require('./services/food_reminder_service');
    try {
      const result = await trigger();
      return res.status(200).json(result);
    } catch (err) {
      return safeError(res, 500, err.message);
    }
  },
);

/// Stops accepting work, lets in-flight requests finish, then exits.
///
/// Without this, every deploy and every scale-down kills whatever was in
/// progress. A scan holds its request open for up to 50 seconds while an AI
/// provider thinks, so on an autoscaling platform -- where instances are
/// recycled routinely, not rarely -- a steady trickle of users see a failed
/// scan for which they have already been charged quota, and the refund path
/// never runs because the process is gone.
///
/// The sequence matters: stop the health check passing FIRST so the load
/// balancer routes new traffic elsewhere, wait a beat for it to notice, then
/// close the listener and drain.
function installGracefulShutdown(server) {
  const DRAIN_MS = Number(process.env.SHUTDOWN_DRAIN_MS || 5000);
  const HARD_LIMIT_MS = Number(process.env.SHUTDOWN_TIMEOUT_MS || 60000);
  let shuttingDown = false;

  const stop = (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;
    isShuttingDown = true;
    console.log(`${signal} received: draining (health now reports shutting_down)`);

    setTimeout(() => {
      server.close(() => {
        console.log('All connections closed, exiting cleanly.');
        process.exit(0);
      });

      // A provider that never answers must not hold the process open forever;
      // the platform would SIGKILL it anyway, but on its schedule, not ours.
      setTimeout(() => {
        console.error('Drain timed out with requests still open, forcing exit.');
        process.exit(1);
      }, HARD_LIMIT_MS).unref();
    }, DRAIN_MS).unref();
  };

  process.on('SIGTERM', () => stop('SIGTERM'));
  process.on('SIGINT', () => stop('SIGINT'));
}

if (require.main === module) {
  const port = process.env.PORT || 3000;

  // No scheduler here, ever. The reminder cron runs in worker.js as a single
  // replica; running it inside an autoscaled API meant one notification per
  // instance, and a long reminder run blocked the event loop serving scans.
  // Drive it from Cloud Scheduler via /api/notifications/food-reminder/trigger
  // if you would rather not run the worker at all.
  const server = app.listen(port, () => {
    console.log(`SnapCal backend running on port ${port}`);
    // Say this once, loudly, at boot. With neither the webhook secret nor the
    // REST key set, purchases never reach the server and every paying user
    // keeps seeing the paywall -- with no error anywhere to notice.
    if (!REVENUECAT_WEBHOOK_AUTH && !REVENUECAT_SECRET_API_KEY) {
      console.error(
        'WARNING: no RevenueCat webhook secret and no REST key are configured. ' +
        'Purchases cannot be verified; every paying user will be treated as free.',
      );
    } else if (!REVENUECAT_SECRET_API_KEY) {
      console.warn(
        'RevenueCat REST key is not configured: the webhook is now a single ' +
        'point of failure, with no fallback when a delivery is missed.',
      );
    }
  });

  // Slightly above the client's own 60s scan timeout, so the server is never
  // the side that hangs up on a scan the app is still waiting for.
  server.keepAliveTimeout = Number(process.env.SERVER_KEEPALIVE_TIMEOUT_MS || 65000);
  server.headersTimeout = server.keepAliveTimeout + 5000;

  installGracefulShutdown(server);
}

module.exports = {
  app,
  normalizeNutrition,
  extractJson,
  normalizeAiJsonText,
  isSafeId,
  calculateNutrition,
  reconcileNutrition,
  enrichScanResults,
  getV2SystemPrompt,
  // Quota arithmetic, exported so the allowance rules can be tested without
  // standing up Firestore.
  bonusScansFor,
  freeAllowanceFor,
  setAuthVerifierForTest(verifier) {
    if (process.env.NODE_ENV !== 'test') {
      throw new Error('Test auth verifier is only available in NODE_ENV=test.');
    }
    authVerifierForTest = verifier;
  },
};
