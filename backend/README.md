# SnapCal Backend Proxy Server

A secure, high-performance Node.js proxy server for the **SnapCal** calorie tracking app. It proxies food image scanning requests to Groq (with Gemini fallback) to keep API keys secure and off client devices.

---

## ⚡ Deployment to Render (Step-by-Step)

Because your code is already synced with GitHub, deploying this backend to [Render](https://render.com) is extremely easy and takes less than 3 minutes.

### Step 1: Create a Render Account
1. Go to [Render.com](https://render.com).
2. Sign up using your **GitHub account**.

### Step 2: Create a New Web Service from GitHub
1. Click **New +** in the upper right and select **Web Service**.
2. Connect your GitHub repository: `Najimbacha/SnapCal`.
3. Give Render a moment to detect that this is a Node.js project.
4. Set the following:
   - **Name**: `snapcal-backend` (or any name you like)
   - **Root Directory**: `backend` (this tells Render to only deploy the Node.js server inside the `backend` folder, instead of trying to run the Flutter code)
   - **Build Command**: `npm install`
   - **Start Command**: `node index.js`
5. Choose the **Free** plan (or any plan you prefer).
6. Click **Create Web Service**.

### Step 3: Add Your API Keys (Environment Variables)
1. Once the service is created, go to the **Environment** tab in your Render dashboard.
2. Click **Add Environment Variable** and add the following:
   - `GROQ_API_KEY` = *[Your actual Groq API Key]*
   - `GEMINI_API_KEY` = *[Your actual Google Gemini API Key]*
3. Render will automatically restart the server with the keys applied.

### Step 4: Generate a Public URL
1. Your service will be assigned a public URL automatically (e.g., `https://snapcal-mxh9.onrender.com`).
2. If you want a custom URL, go to the **Settings** tab and configure a custom domain.
3. **Copy this URL** — you will use it in your Flutter app configuration (`app_constants.dart`).

---

## 🔍 How to Monitor Your Proxy Server

### Check Service Health
Open your web browser and visit:
`https://[your-render-domain].onrender.com/health`

You should see a JSON response confirming the server status:
```json
{
  "status": "ok",
  "timestamp": "2026-05-23T12:00:00.000Z"
}
```

### View Live Execution Logs
1. Open the Render dashboard.
2. Click on your deployed web service.
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
