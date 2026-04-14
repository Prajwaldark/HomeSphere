# Appliance Vision Backend

This backend keeps the Gemini API key off the Flutter client.

## Deploy online

This repo is set up for a Vercel serverless API:

- API file: `api/appliance-detect.mjs`
- Shared Gemini logic: `server/applianceVisionCore.mjs`
- Vercel config: `vercel.json`

In Vercel, add these environment variables:

- `GEMINI_API_KEY`
- `GEMINI_VISION_MODEL` (optional, defaults to `gemini-2.5-flash`)
- `GEMINI_BASE_URL` (optional)

After deployment, your public endpoint will look like:

```text
https://your-project.vercel.app/api/appliance-detect
```

## Flutter app

Run Flutter with your deployed backend URL:

```powershell
flutter run --dart-define=APPLIANCE_VISION_API_URL=https://your-project.vercel.app/api/appliance-detect
```

## Optional local backend

If you still want to test locally, this repo also includes a small Node server:

```powershell
copy server\.env.example server\.env
npm run api
```
