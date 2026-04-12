# SpeakUp Backend

This backend powers two Gemini features for SpeakUp:

- `POST /generate-drill`
- `POST /speech-feedback`

It is designed so the iPhone app never ships a Gemini API key. The app talks to this server, and this server talks to Gemini.

## Local setup

1. Install Node.js 20+.
2. Copy `.env.example` to `.env`.
3. Add your `GEMINI_API_KEY`.
4. Set `GEMINI_MODEL` if you want to override the default. The current default is `gemini-2.5-flash-lite`.
5. Install dependencies:

```bash
cd backend
npm install
```

6. Start the server:

```bash
npm run dev
```

The server listens on `http://127.0.0.1:8787` by default.

## Deploy to Render

This repo now includes a Render Blueprint at [`render.yaml`](/Users/jiaweihuang/Documents/SpeakUpApp/SpeakUp/render.yaml), so you can deploy without manually recreating service settings.

### First deploy

1. Push this repo to GitHub.
2. In Render, choose `New +` -> `Blueprint`.
3. Select this repository.
4. Render will detect `render.yaml` and create one web service named `speakup-backend`.
5. When prompted, set `GEMINI_API_KEY`.
6. Deploy.

Render will build the service from the monorepo `backend` directory using:

- Build command: `npm install`
- Start command: `npm start`
- Health check: `/health`

After the deploy finishes, Render gives you a public URL like:

```text
https://speakup-backend.onrender.com
```

Your production endpoints will then be:

- `https://YOUR-RENDER-URL/generate-drill`
- `https://YOUR-RENDER-URL/speech-feedback`

### Updating SpeakUp to use the deployed backend

Once you have your Render URL, point the app at it in Xcode:

1. Open the `SpeakUp` project in Xcode.
2. Select the `SpeakUp` target.
3. Open `Build Settings`.
4. Search for:
   - `SpeakUpDrillGenerationEndpoint`
   - `SpeakUpFeedbackEndpoint`
5. Replace the current debug localhost values with your Render URLs if you want simulator/device builds to use production during testing.
6. Set the same values for `Release`.

Example:

```text
SpeakUpDrillGenerationEndpoint = https://YOUR-RENDER-URL/generate-drill
SpeakUpFeedbackEndpoint = https://YOUR-RENDER-URL/speech-feedback
```

## How billing works

Your Gemini usage will be billed to whatever Google account/project owns the `GEMINI_API_KEY` you place on Render.

That means:

- the iPhone app itself does not hold the Gemini key
- Render just hosts the server
- Google bills the Gemini account behind that key

## Routes

### `GET /health`

Returns a small health payload so Render can verify the service is alive.

### `POST /generate-drill`

Accepts the app's `DrillGenerationRequest` shape and returns one generated drill in the app's JSON format.

### `POST /speech-feedback`

Accepts the app's `SpeechFeedbackRequest` shape and returns supportive Gemini coaching.
