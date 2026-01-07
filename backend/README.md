# Endless Future Backend

Secure backend proxy server for the Endless Future iOS app. This server keeps your Gemini API key secure on the server side, never exposing it to the client application.

## Security Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   iOS App       │────▶│  Backend Proxy  │────▶│  Gemini API     │
│  (No API Key)   │     │  (API Key Here) │     │  (Google)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

The iOS app never sees the API key. All requests go through this backend, which adds the API key server-side.

## Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Environment
```bash
# Copy the example config
cp .env.example .env

# Edit .env and add your Gemini API key
# Get your key at: https://aistudio.google.com/app/apikey
```

### 3. Run the Server
```bash
npm start
```

The server will start on port 3000 (or your configured PORT).

## API Endpoints

### Health Check
```
GET /health
```
Returns server status. Use this to verify the backend is running.

### Generate Plan
```
POST /api/v1/plan/generate
Content-Type: application/json

{
    "identityType": "fit_disciplined",
    "customIdentityName": null,
    "timeHorizon": "3months",
    "availability": "normal",
    "intensity": "balanced",
    "planConfidence": "balanced",
    "isFirstWeek": true,
    "startDate": "2024-01-08T00:00:00Z"
}
```

### Adapt Plan
```
POST /api/v1/plan/adapt
Content-Type: application/json

{
    "weekNumber": 1,
    "weekFeeling": "good",
    "completionRate": 0.75,
    "engagementRate": 0.80,
    "blocksCompleted": 15,
    "blocksSkipped": 3,
    "blocksMoved": 2,
    "blocksReduced": 0,
    "currentPlanConfidence": "balanced"
}
```

### General Chat
```
POST /api/v1/chat
Content-Type: application/json

{
    "message": "What's a good morning routine for productivity?",
    "context": "I'm working toward becoming more disciplined"
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GEMINI_API_KEY` | Your Google Gemini API key | Required |
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment (development/production) | development |
| `ALLOWED_ORIGINS` | CORS allowed origins (comma-separated) | * |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window in ms | 60000 |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | 30 |

## Deployment

### For Production

1. **Never commit your `.env` file** - it contains your API key
2. Set environment variables in your hosting platform (Heroku, Railway, Render, etc.)
3. Update `ALLOWED_ORIGINS` to your app's domain
4. Use HTTPS in production

### Example: Deploy to Railway
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

Then set your environment variables in the Railway dashboard.

## Connecting from iOS

In your iOS app, the `GeminiBackendService` is already configured to connect to this backend. For local development:

1. Run this backend server (`npm start`)
2. The iOS simulator can reach `localhost:3000`
3. For physical devices, use your computer's local IP address

For production, update `BackendConfiguration.serverURL` in `GeminiBackendService.swift` with your deployed backend URL.

## Troubleshooting

**"GEMINI_API_KEY not configured"**
- Make sure you've created a `.env` file with your API key

**iOS app can't connect**
- Verify the backend is running: `curl http://localhost:3000/health`
- Check the backend URL in `GeminiBackendService.swift`
- For physical iOS devices, use your computer's IP instead of localhost

**Rate limited**
- Default is 30 requests per minute
- Adjust `RATE_LIMIT_MAX_REQUESTS` in `.env` if needed
