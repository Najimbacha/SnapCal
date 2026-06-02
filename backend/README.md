# SnapCal Backend Proxy Server

A secure, high-performance Node.js proxy server for the **SnapCal** calorie tracking app. It proxies food image scanning requests to Groq (with Gemini fallback) to keep API keys secure and off client devices.

---

## ⚡ Deployment to Railway (Step-by-Step)

Because your code is already synced with GitHub, deploying this backend to [Railway](https://railway.app) is extremely easy and takes less than 3 minutes.

### Step 1: Create a Railway Account
1. Go to [Railway.app](https://railway.app).
2. Sign up using your **GitHub account**.

### Step 2: Create a New Project from GitHub
1. Click **New Project** in the upper right.
2. Select **Deploy from GitHub repo**.
3. Choose your repository: `Najimbacha/SnapCal`.
4. Under **Settings / Source Directory**, type `backend` (this tells Railway to only deploy the Node.js server inside the `backend` folder, instead of trying to run the Flutter code).
5. Click **Deploy**.

### Step 3: Add Your API Keys (Environment Variables)
1. Click on the deployed service in your Railway dashboard.
2. Go to the **Variables** tab.
3. Click **New Variable** and add the following:
   * `GROQ_API_KEY` = *[Your actual Groq API Key]*
   * `GEMINI_API_KEY` = *[Your actual Google Gemini API Key]*
4. Railway will automatically restart the server with the keys applied.

### Step 4: Generate a Public Domain
1. In your Railway service, go to the **Settings** tab.
2. Under the **Public Networking** / **Domains** section, click **Generate Domain**.
3. Railway will generate a public URL for your proxy (e.g., `https://backend-production-xxxx.up.railway.app`).
4. **Copy this URL** — you will use it in your Flutter app configuration.

---

## 🔍 How to Monitor Your Proxy Server

### Check Service Health
Open your web browser and visit:
`https://[your-railway-domain].up.railway.app/health`

You should see a JSON response confirming the server status:
```json
{
  "status": "ok",
  "timestamp": "2026-05-23T12:00:00.000Z"
}
```

### View Live Execution Logs
1. Open the Railway project dashboard.
2. Click on your deployed service.
3. Go to the **Logs** tab.
4. You will see real-time console prints (e.g., `Proxy: Attempting scan with Groq...`, `Proxy: Gemini fallback scan succeeded.`) for every scan request.

---

## ⚙️ Local Development
If you want to run the proxy server locally on your computer:
1. Make sure [Node.js](https://nodejs.org) is installed.
2. Open terminal in the `backend` folder:
   ```bash
   cd backend
   npm install
   ```
3. Open the `.env` file and replace the placeholders with your actual API keys.
4. Start the server:
   ```bash
   npm start
   ```
5. The local server will run on `http://localhost:3000`.
