require('dotenv').config();

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const axios = require('axios');
const admin = require('firebase-admin');
const rateLimit = require('express-rate-limit');

const MAX_JSON_BODY = process.env.MAX_JSON_BODY || '10mb';
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const FREE_MONTHLY_SCANS = Number(process.env.FREE_MONTHLY_SCANS || 3);
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

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) return;

  const options = {};
  if (process.env.FIREBASE_STORAGE_BUCKET) {
    options.storageBucket = process.env.FIREBASE_STORAGE_BUCKET;
  }

  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      options.credential = admin.credential.cert(serviceAccount);
      admin.initializeApp(options);
      console.log('Firebase Admin initialized with service account from environment');
      return;
    } catch (err) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT JSON:', err.message);
    }
  }

  admin.initializeApp(options);
  console.log('Firebase Admin initialized with application default credentials');
}

initializeFirebaseAdmin();

const { startScheduler } = require('./cron/scheduler');

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
app.use(express.json({ limit: MAX_JSON_BODY, type: 'application/json' }));
app.use(express.urlencoded({ limit: MAX_JSON_BODY, extended: false }));

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: Number(process.env.API_RATE_LIMIT || 120),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests. Please try again later.' },
});

const scanLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: Number(process.env.SCAN_RATE_LIMIT || 20),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many scan requests. Please try again later.' },
});

const webhookLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: Number(process.env.WEBHOOK_RATE_LIMIT || 120),
  standardHeaders: true,
  legacyHeaders: false,
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
    return safeError(res, 401, 'Authentication required.');
  }

  try {
    const decodedToken = authVerifierForTest
      ? await authVerifierForTest(match[1])
      : await admin.auth().verifyIdToken(match[1], true);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email || null,
      admin: decodedToken.admin === true,
    };
    return next();
  } catch (error) {
    console.error('Auth token rejected:', error.message);
    return safeError(res, 401, 'Authentication required.');
  }
}

async function verifyAppCheck(req, res, next) {
  if (!REQUIRE_APP_CHECK) return next();
  const token = req.header('X-Firebase-AppCheck');
  if (!token) {
    return safeError(res, 401, 'App Check required.');
  }
  try {
    await admin.appCheck().verifyToken(token);
    return next();
  } catch (error) {
    console.error('App Check token rejected:', error.message);
    return safeError(res, 401, 'App Check required.');
  }
}

function requireAdmin(req, res, next) {
  if (req.user?.admin === true) return next();
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

async function getPremiumStatus(uid) {
  const snap = await subscriptionDoc(uid).get();
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
        } catch (error) {
          console.error('Subscription mirror write failed:', error.message);
        }
      }
    }
  }

  // Mirror the authoritative monthly quota so the client displays what the
  // server will actually enforce, instead of its own local guess (BUG-005).
  let scansRemaining = null;
  if (!active) {
    try {
      const useSnap = await usageDoc(uid).get();
      const usage = useSnap.exists ? useSnap.data() : {};
      const monthKey = currentMonthKey();
      const scansUsed = usage.monthKey === monthKey ? Number(usage.scansUsed || 0) : 0;
      scansRemaining = Math.max(0, FREE_MONTHLY_SCANS - scansUsed);
    } catch (error) {
      console.error('Usage read failed for premium status:', error.message);
    }
  }

  return {
    isActive: active,
    entitlementId: data?.entitlementId || null,
    productId: data?.productId || null,
    expiresAt: expiresAt || null,
    source: data?.source || null,
    lastVerifiedAt: data?.lastVerifiedAt || null,
    monthlyScanLimit: FREE_MONTHLY_SCANS,
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

    if (!isPremium && scansUsed >= FREE_MONTHLY_SCANS) {
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

    if (!isPremium && scansUsed >= FREE_MONTHLY_SCANS) {
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

async function callAiWithImage(base64Data, language, customPrompt = null, useV2 = false) {
  const systemPrompt = customPrompt || (useV2 ? getV2SystemPrompt(language) : getSystemPrompt(language));
  const providerKey = process.env.OPENROUTER_API_KEY || process.env.QWEN_API_KEY;
  const geminiApiKeys = (process.env.GEMINI_API_KEYS || process.env.GEMINI_API_KEY || '').split(',').map(k => k.trim()).filter(Boolean);
  const maxRetries = Number(process.env.AI_RETRY_LIMIT) || 3;
  const baseDelay = Number(process.env.AI_RETRY_DELAY_MS) || 2000;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    const deepseekKey = process.env.DEEPSEEK_API_KEY;
    if (deepseekKey) {
      try {
        const response = await axios.post(
          'https://api.deepseek.com/chat/completions',
          {
            model: process.env.DEEPSEEK_SCANNER_MODEL || 'deepseek-v4-flash-vision-exp',
            messages: [{
              role: 'user',
              content: [
                { type: 'text', text: systemPrompt },
                { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Data}` } },
              ],
            }],
            temperature: 0.4,
            max_tokens: 1024,
          },
          {
            headers: { Authorization: `Bearer ${deepseekKey}`, 'Content-Type': 'application/json' },
            timeout: 20000,
          },
        );
        const content = response.data?.choices?.[0]?.message?.content;
        if (content) return stripThink(content);
        throw new Error('empty-deepseek-response');
      } catch (err) {
        console.error(`DeepSeek vision scan failed (attempt ${attempt}/${maxRetries}):`, err.response?.data || err.message);
        if (process.env.DEEPSEEK_STRICT === 'true') {
          const detail = err.response?.data ? JSON.stringify(err.response.data).slice(0, 500) : err.message;
          throw new Error(`deepseek-strict-failed: ${detail}`);
        }
      }
    }

    if (providerKey) {
      try {
        const response = await axios.post(
          'https://openrouter.ai/api/v1/chat/completions',
          {
            model: process.env.SCANNER_MODEL || 'qwen/qwen3-vl-8b-instruct',
            messages: [{
              role: 'user',
              content: [
                { type: 'text', text: systemPrompt },
                { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Data}` } },
              ],
            }],
            temperature: 0.4,
            max_tokens: 1024,
          },
          {
            headers: { Authorization: `Bearer ${providerKey}`, 'Content-Type': 'application/json', 'HTTP-Referer': 'https://snapcal.com', 'X-Title': 'SnapCal' },
            timeout: 20000,
          },
        );
        const content = response.data?.choices?.[0]?.message?.content;
        if (content) return stripThink(content);
      } catch (err) {
        console.error(`Primary AI scan failed (attempt ${attempt}/${maxRetries}):`, err.response?.data || err.message);
      }
    }

    const groqKey = process.env.GROQ_API_KEY;
    if (groqKey) {
      try {
        const response = await axios.post(
          'https://api.groq.com/openai/v1/chat/completions',
          {
            model: process.env.GROQ_VISION_MODEL || 'qwen/qwen3.6-27b',
            messages: [{
              role: 'user',
              content: [
                { type: 'text', text: systemPrompt },
                { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Data}` } },
              ],
            }],
            temperature: 0.4,
            max_tokens: 1024,
          },
          {
            headers: { Authorization: `Bearer ${groqKey}`, 'Content-Type': 'application/json' },
            timeout: 20000,
          },
        );
        const content = response.data?.choices?.[0]?.message?.content;
        if (content) return stripThink(content);
      } catch (err) {
        console.error(`Groq vision scan failed (attempt ${attempt}/${maxRetries}):`, err.response?.data || err.message);
      }
    }

    if (geminiApiKeys.length > 0) {
      const geminiKey = geminiApiKeys[(attempt - 1) % geminiApiKeys.length];
      try {
        const response = await axios.post(
          `https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_SCANNER_MODEL || 'gemini-2.0-flash'}:generateContent`,
          {
            contents: [{
              parts: [
                { text: systemPrompt },
                { inline_data: { mime_type: 'image/jpeg', data: base64Data } },
              ],
            }],
            generationConfig: { temperature: 0.4, maxOutputTokens: 512 },
          },
          { headers: { 'Content-Type': 'application/json', 'x-goog-api-key': geminiKey }, timeout: 15000 },
        );
        const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text) return stripThink(text);
        throw new Error('empty-gemini-response');
      } catch (err) {
        console.error(`Gemini scan failed (attempt ${attempt}/${maxRetries}, key ${(attempt - 1) % geminiApiKeys.length + 1}/${geminiApiKeys.length}):`, {
          status: err.response?.status,
          data: err.response?.data,
          message: err.message,
        });
      }
    }

    if (attempt < maxRetries) {
      const delay = baseDelay * attempt;
      console.error(`All providers failed, retrying in ${delay}ms (attempt ${attempt}/${maxRetries})...`);
      await new Promise(r => setTimeout(r, delay));
    }
  }

  throw new Error('ai-scan-failed');
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

  const geminiApiKey = process.env.GEMINI_API_KEY;
  if (geminiApiKey) {
    try {
      const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/${options.model || process.env.GEMINI_TEXT_MODEL || 'gemini-2.0-flash'}:generateContent`,
        {
          contents: [{ parts: [{ text: effectivePrompt }] }],
          generationConfig: {
            temperature,
            maxOutputTokens,
            ...(options.responseMimeType ? { responseMimeType: options.responseMimeType } : {}),
          },
        },
        { headers: { 'Content-Type': 'application/json', 'x-goog-api-key': geminiApiKey }, timeout },
      );
      const candidate = response.data?.candidates?.[0];
      const text = candidate?.content?.parts?.[0]?.text;
      if (text) return requireJson ? normalizeAiJsonText(text) : text;

      const reason = candidate?.finishReason
        || response.data?.promptFeedback?.blockReason
        || 'no-text-in-response';
      console.error(`Gemini text returned no usable text (finishReason=${reason}, maxOutputTokens=${maxOutputTokens}). Trying next provider.`);
      failures.push(`gemini:${reason}`);
    } catch (err) {
      const detail = detailOf(err);
      console.error('Gemini text failed:', detail);
      failures.push(`gemini:${detail}`);
    }
  }

  // OpenAI-compatible fallbacks, in order. Keys that are not configured are
  // skipped rather than treated as a fatal misconfiguration.
  const fallbacks = [
    {
      name: 'groq',
      key: process.env.GROQ_API_KEY,
      url: 'https://api.groq.com/openai/v1/chat/completions',
      model: options.groqTextModel || process.env.GROQ_TEXT_MODEL || 'llama-3.3-70b-versatile',
    },
    {
      name: 'deepseek',
      key: process.env.DEEPSEEK_API_KEY,
      url: 'https://api.deepseek.com/chat/completions',
      model: process.env.DEEPSEEK_TEXT_MODEL || 'deepseek-chat',
    },
    {
      name: 'openrouter',
      key: process.env.OPENROUTER_API_KEY || process.env.QWEN_API_KEY,
      url: 'https://openrouter.ai/api/v1/chat/completions',
      model: options.textModel || process.env.TEXT_MODEL || 'qwen/qwen-plus',
      extraHeaders: { 'HTTP-Referer': 'https://snapcal.com', 'X-Title': 'SnapCal' },
    },
  ].filter((provider) => provider.key);

  if (!geminiApiKey && fallbacks.length === 0) throw new Error('ai-not-configured');

  for (const provider of fallbacks) {
    try {
      const response = await axios.post(
        provider.url,
        {
          model: provider.model,
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
            Authorization: `Bearer ${provider.key}`,
            'Content-Type': 'application/json',
            ...(provider.extraHeaders || {}),
          },
          timeout,
        },
      );
      const content = response.data?.choices?.[0]?.message?.content;
      if (content) {
        const cleaned = stripThink(content);
        if (cleaned) return requireJson ? normalizeAiJsonText(cleaned) : cleaned;
      }
      console.error(`${provider.name} text returned empty content (model=${provider.model}).`);
      failures.push(`${provider.name}:empty-response`);
    } catch (err) {
      const detail = detailOf(err);
      console.error(`${provider.name} text failed (model=${provider.model}):`, detail);
      failures.push(`${provider.name}:${detail}`);
    }
  }

  throw new Error(`ai-text-unavailable: ${failures.join(' | ') || 'no-providers-configured'}`);
}

async function writeAuditLog({ actorUid, action, targetUid, result, metadata = {} }) {
  await db.collection('auditLogs').add({
    actorUid,
    action,
    targetUid,
    result,
    metadata,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'SnapCal Backend' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
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

  const storagePath = `users/${uid}/scans/${scanId}/${fileName}`;
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
    if (error.code === 402) return safeError(res, 402, 'Scan limit reached.');
    if (error.code === 409) return safeError(res, 409, 'Scan is already processing.');
    return safeError(res, 404, 'Scan not found.');
  }

  try {
    const storagePath = scan.storagePath;
    if (!storagePath || !storagePath.startsWith(`users/${uid}/scans/${scanId}/`)) {
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
  if (storagePath?.startsWith(`users/${uid}/scans/${scanId}/`)) {
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
    return safeError(res, 401, 'Unauthorized webhook.');
  }

  const event = req.body?.event;
  if (!assertPlainObject(event)) return safeError(res, 400, 'Invalid webhook.');

  const eventId = String(event.id || crypto.createHash('sha256').update(JSON.stringify(event)).digest('hex'));
  const appUserId = String(event.app_user_id || event.original_app_user_id || '');
  if (!isSafeId(appUserId)) return safeError(res, 400, 'Invalid webhook user.');

  const eventRef = db.collection('revenueCatEvents').doc(eventId);
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
          processed: true,
        });
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
        processed: true,
      });
    });
    return res.status(200).json({ ok: true });
  } catch (error) {
    console.error('RevenueCat webhook failed:', error.message);
    return safeError(res, 500, 'Webhook processing failed.');
  }
});

app.get('/api/admin/users/:uid/summary', authenticateToken, verifyAppCheck, requireAdmin, async (req, res) => {
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

app.post('/api/admin/users/:uid/access', authenticateToken, verifyAppCheck, requireAdmin, async (req, res) => {
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
app.post('/v1/scan', scanLimiter, authenticateToken, verifyAppCheck, async (req, res) => {
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

    console.log(JSON.stringify({ event: 'scan.success', pipeline: 'v1', status: 200 }));
    console.error('Scan items:', JSON.stringify(nutrition.items.map(i => ({ food_name: i.food_name, calories: i.calories }))));

    return res.status(200).json({ items: nutrition.items, totals });
  } catch (error) {
    // The quota was consumed up-front; give it back when the scan itself
    // failed so users are not charged for our provider outages.
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
    await userDoc(uid).collection('settings').doc('app').set({
      foodRemindersEnabled: enabled,
      fcmToken: fcmToken || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error('Food reminder register failed:', err.message);
    return safeError(res, 500, 'Could not register food reminder preference.');
  }
});

// Admin-only: this runs the reminder fan-out for every user (BUG-018).
app.post(
  '/api/notifications/food-reminder/trigger',
  authenticateToken,
  verifyAppCheck,
  requireAdmin,
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

if (require.main === module) {
  const port = process.env.PORT || 3000;
  startScheduler();
  app.listen(port, () => {
    console.log(`SnapCal backend running on port ${port}`);
  });
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
  setAuthVerifierForTest(verifier) {
    if (process.env.NODE_ENV !== 'test') {
      throw new Error('Test auth verifier is only available in NODE_ENV=test.');
    }
    authVerifierForTest = verifier;
  },
};
