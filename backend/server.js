require('dotenv').config();

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const axios = require('axios');
const admin = require('firebase-admin');
const rateLimit = require('express-rate-limit');

const MAX_JSON_BODY = process.env.MAX_JSON_BODY || '1mb';
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const FREE_MONTHLY_SCANS = Number(process.env.FREE_MONTHLY_SCANS || 3);
const REQUIRE_APP_CHECK = process.env.REQUIRE_APP_CHECK === 'true';
const REVENUECAT_WEBHOOK_AUTH = process.env.REVENUECAT_WEBHOOK_AUTH || '';

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

const app = express();
const db = admin.firestore();
let authVerifierForTest = null;

app.disable('x-powered-by');
app.use(cors({ origin: true }));
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
      "insights": ["string", "string"]
    }
  ]
}

Rules:
- Each distinct food item visible on the plate gets its own entry in the "items" array
- health_score is based on nutritional density (10 = superfood, 1 = junk food)
- insights should be short positive or cautionary highlights
- All nutritional values are for a typical single serving
- protein, carbs, fat are in grams
- If NOT food at all, return: {"items": [{"food_name": "${notFood.food_name}", "health_score": 0, "insights": ["${notFood.insights[0]}"], "calories": 0, "protein": 0, "carbs": 0, "fat": 0}]}`;
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

async function getPremiumStatus(uid) {
  const snap = await subscriptionDoc(uid).get();
  const data = snap.exists ? snap.data() : {};
  const expiresAt = data?.expiresAt;
  const expiresDate = expiresAt?.toDate ? expiresAt.toDate() : null;
  const active = data?.isActive === true && (!expiresDate || expiresDate > new Date());
  return {
    isActive: active,
    entitlementId: data?.entitlementId || null,
    productId: data?.productId || null,
    expiresAt: expiresAt || null,
    source: data?.source || null,
    lastVerifiedAt: data?.lastVerifiedAt || null,
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

function normalizeNutrition(rawText) {
  const jsonText = extractJson(rawText);
  const decoded = JSON.parse(jsonText);
  const items = Array.isArray(decoded?.items) ? decoded.items : [decoded];
  const cleaned = items.map((item) => ({
    food_name: String(item.food_name || item.foodName || 'Unknown Food').slice(0, 120),
    portion: String(item.portion || 'Standard portion').slice(0, 120),
    calories: clampInt(item.calories, 0, 5000),
    protein: clampInt(item.protein, 0, 500),
    carbs: clampInt(item.carbs, 0, 800),
    fat: clampInt(item.fat, 0, 500),
    health_score: clampInt(item.health_score ?? item.healthScore ?? 5, 0, 10),
    insights: Array.isArray(item.insights) ? item.insights.slice(0, 3).map((v) => String(v).slice(0, 40)) : [],
  }));
  if (cleaned.length === 0) throw new Error('empty-nutrition-result');
  return { items: cleaned };
}

function extractJson(text) {
  const cleaned = String(text || '').replace(/```(?:json)?/gi, '').replace(/```/g, '').trim();
  const start = cleaned.indexOf('{');
  if (start < 0) throw new Error('json-not-found');

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

  throw new Error('json-not-found');
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

async function callAiWithImage(base64Data, language, customPrompt = null) {
  const systemPrompt = customPrompt || getSystemPrompt(language);
  const groqApiKey = process.env.GROQ_API_KEY;
  let groqError = null;

  if (groqApiKey) {
    try {
      const response = await axios.post(
        'https://api.groq.com/openai/v1/chat/completions',
        {
          model: process.env.GROQ_SCANNER_MODEL || 'meta-llama/llama-4-scout-17b-16e-instruct',
          messages: [{
            role: 'user',
            content: [
              { type: 'text', text: systemPrompt },
              { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Data}` } },
            ],
          }],
          temperature: 0.4,
        },
        {
          headers: { Authorization: `Bearer ${groqApiKey}`, 'Content-Type': 'application/json' },
          timeout: 12000,
        },
      );
      const content = response.data?.choices?.[0]?.message?.content;
      if (content) return content;
    } catch (err) {
      groqError = err.response?.data || err.message;
      console.error('Groq scan failed:', groqError);
    }
  }

  const geminiApiKey = process.env.GEMINI_API_KEY;
  if (!geminiApiKey) throw new Error('ai-not-configured');

  try {
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/${process.env.GEMINI_SCANNER_MODEL || 'gemini-2.5-flash'}:generateContent?key=${geminiApiKey}`,
      {
        contents: [{
          parts: [
            { text: systemPrompt },
            { inline_data: { mime_type: 'image/jpeg', data: base64Data } },
          ],
        }],
        generationConfig: { temperature: 0.4, maxOutputTokens: 512 },
      },
      { headers: { 'Content-Type': 'application/json' }, timeout: 10000 },
    );
    const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (text) return text;
    throw new Error('empty-gemini-response');
  } catch (err) {
    console.error('Gemini scan failed:', err.response?.data || err.message, 'Groq:', groqError);
    throw new Error('ai-scan-failed');
  }
}

async function callAiText(prompt, options = {}) {
  const requireJson = options.responseMimeType === 'application/json' || options.requireJson === true;
  const effectivePrompt = requireJson ? buildJsonPrompt(prompt) : prompt;
  const geminiApiKey = process.env.GEMINI_API_KEY;
  if (geminiApiKey) {
    try {
      const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/${options.model || process.env.GEMINI_TEXT_MODEL || 'gemini-2.5-flash'}:generateContent?key=${geminiApiKey}`,
        {
          contents: [{ parts: [{ text: effectivePrompt }] }],
          generationConfig: {
            temperature: requireJson ? 0.2 : (options.temperature ?? 0.7),
            maxOutputTokens: options.maxOutputTokens || 2048,
            ...(options.responseMimeType ? { responseMimeType: options.responseMimeType } : {}),
          },
        },
        { headers: { 'Content-Type': 'application/json' }, timeout: options.timeout || 25000 },
      );
      const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (text) return requireJson ? normalizeAiJsonText(text) : text;
    } catch (err) {
      console.error('Gemini text failed:', err.response?.data || err.message);
    }
  }

  const groqApiKey = process.env.GROQ_API_KEY;
  if (!groqApiKey) throw new Error('ai-not-configured');
  const groqPayload = {
    model: options.groqModel || process.env.GROQ_TEXT_MODEL || 'llama-3.1-8b-instant',
    messages: [
      ...(requireJson ? [{ role: 'system', content: 'Return only valid JSON. No markdown. No prose.' }] : []),
      { role: 'user', content: effectivePrompt },
    ],
    max_tokens: options.maxOutputTokens || 2048,
    temperature: requireJson ? 0.2 : (options.temperature ?? 0.7),
    ...(requireJson ? { response_format: { type: 'json_object' } } : {}),
  };
  let response;
  try {
    response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      groqPayload,
      { headers: { Authorization: `Bearer ${groqApiKey}`, 'Content-Type': 'application/json' }, timeout: options.timeout || 25000 },
    );
  } catch (err) {
    if (!requireJson || err.response?.status !== 400) throw err;
    const retryPayload = { ...groqPayload };
    delete retryPayload.response_format;
    response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      retryPayload,
      { headers: { Authorization: `Bearer ${groqApiKey}`, 'Content-Type': 'application/json' }, timeout: options.timeout || 25000 },
    );
  }
  const content = response.data?.choices?.[0]?.message?.content;
  if (!content) throw new Error('empty-groq-response');
  return requireJson ? normalizeAiJsonText(content) : content;
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
    console.error('AI text request failed:', error.message);
    return safeError(res, 500, 'AI request failed.');
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
  if (req.header('Authorization') !== REVENUECAT_WEBHOOK_AUTH) {
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
      const isActive = ![
        'EXPIRATION',
        'CANCELLATION',
        'BILLING_ISSUE',
        'PRODUCT_CHANGE',
        'REFUND',
        'TRANSFER',
      ].includes(type) && (expirationMs === 0 || expirationMs > Date.now());

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

// Backward compatible endpoint: authenticated, but no longer accepts anonymous public traffic.
app.post('/api/scan-food', scanLimiter, authenticateToken, verifyAppCheck, async (req, res) => {
  return safeError(res, 410, 'Use the private upload scan flow.');
});

app.use((err, req, res, next) => {
  if (err?.type === 'entity.too.large') {
    return safeError(res, 413, 'Request body too large.');
  }
  console.error('Unhandled server error:', err.stack || err.message);
  return safeError(res, 500, 'Internal server error.');
});

if (require.main === module) {
  const port = process.env.PORT || 3000;
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
  setAuthVerifierForTest(verifier) {
    if (process.env.NODE_ENV !== 'test') {
      throw new Error('Test auth verifier is only available in NODE_ENV=test.');
    }
    authVerifierForTest = verifier;
  },
};
