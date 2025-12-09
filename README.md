# Agri-Guide

Agri-Guide is a cross-platform mobile application (Flutter) that provides agricultural guidance, a community feed, learning tutorials, weather information, and an AI-powered advisory system with optional voice (TTS) responses.

This repository contains the Flutter frontend for the Agri-Guide app. The app communicates with a backend API (default: `https://agriguide-backend-79j2.onrender.com`) for authentication, content, AI chat, voice features, and notifications.

**Key features**

- User authentication and profile management
- Community posts (create, like, comment)
- Learning Management System (tutorials)
- Daily farming tips
- Weather integration (OpenWeatherMap)
- AI chat assistant (text) and optional Voice AI (TTS) responses
- Local notifications and deep-linking

---

**Table of contents**

- [Requirements](#requirements)
- [Environment variables](#environment-variables)
- [Getting started](#getting-started)
- [Running the app](#running-the-app)
- [Project structure](#project-structure)
- [Voice AI & docs](#voice-ai--docs)
- [Testing & debugging](#testing--debugging)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [License & notes](#license--notes)

---

## Requirements

- Flutter SDK (see `pubspec.yaml` for the Dart SDK constraint).
- Android Studio or Xcode for platform builds and emulators.
- A running backend (default base URL: `https://agriguide-backend-79j2.onrender.com`) or local backend for development.
- (Optional) An OpenWeatherMap API key for weather features.

## Environment variables

This project uses `flutter_dotenv` to load environment variables from a `.env` file in the project root. Do NOT commit your `.env` with secrets. A `.gitignore` entry for `.env` is already present.

- A sample `.env.example` has been added to the repo. Copy it to `.env` and fill in real values before running the app.

Important variables (examples in `.env.example`):

- `BACKEND_BASE_URL` — backend base URL (default provided)
- `OPENWEATHER_API_KEY` — API key for OpenWeatherMap
- `NOTIFICATION_POLL_INTERVAL` — polling interval for notifications (seconds)
- `DEFAULT_LANGUAGE` / `SUPPORTED_LANGUAGES`

## Getting started

1. Clone the repository (you already have a copy).

2. Install Flutter and platform tools. On Windows, make sure you can run `flutter` from PowerShell.

3. Install dependencies:

```powershell
flutter pub get
```

4. Create your `.env` from the example and provide values:

```powershell
copy .env.example .env
# then edit .env in your editor and add keys
```

## Running the app

- Run on the default connected device / emulator:

```powershell
flutter run
```

- Run on a specific Android emulator:

```powershell
flutter devices
flutter run -d <device-id>
```

- Build release APK (Android):

```powershell
flutter build apk --release
```

## Project structure

Top-level (relevant parts):

```
Agri-Guide/
├─ android/  (Android native project)
├─ ios/      (iOS native project)
├─ lib/
│  ├─ config/         (app config like `api_config.dart`, routes, theme)
│  ├─ services/       (API services: auth, ai_service, community_api_service, weather_service, voice_ai_service, ...)
│  ├─ screens/        (UI screens, onboarding, home, auth)
│  ├─ widgets/        (reusable widgets)
│  ├─ models/         (data models)
│  └─ main.dart       (app entry; loads `.env` via `flutter_dotenv`)
├─ assets/            (images, fonts, system_instruction.json)
├─ pubspec.yaml
├─ .env               (local, NOT committed)
├─ .env.example       (placeholders for required env variables)
└─ documentation files (VOICE_README.md, VOICE_QUICK_START.md, etc.)
```

### Notable files

- `lib/main.dart` — initializes `dotenv`, local notifications and providers.
- `lib/config/api_config.dart` — backend base URL (defaults to production Render URL but contains commented local options).
- `lib/services/weather_service.dart` — loads `OPENWEATHER_API_KEY` from `dotenv`.
- `lib/services/*_api_service.dart` — communicate with backend using `BACKEND_BASE_URL`.

## Voice AI & docs

This project includes voice AI integration (Text + optional TTS). Comprehensive docs are included in the repository:

- `VOICE_README.md` — documentation index
- `VOICE_QUICK_START.md` — user/dev quick start
- `VOICE_AI_INTEGRATION.md` — API details and examples
- `VOICE_ARCHITECTURE.md` — system architecture and diagrams
- `VOICE_INTEGRATION_SUMMARY.md` — implementation overview

If you are working on voice features, read those docs first — they describe endpoints such as `/api/voice/chat/` and `/api/voice/voices/` and outline how the client expects audio responses.

## Testing & debugging

- Enable `DEBUG_MODE` in your `.env` to enable verbose logging (if the app respects that variable).
- Common commands:

```powershell
# Run unit/widget tests
flutter test

# Analyze code
flutter analyze
```

## Contributing

- Follow existing code style (Dart/Flutter null-safety).
- Add new environment variables to `.env.example` and document them.
- Keep sensitive data out of version control.

## Troubleshooting

- If you see backend connection errors, ensure `BACKEND_BASE_URL` points to a reachable backend.
- For Android emulator local backend use `http://10.0.2.2:8000` and set `BACKEND_BASE_URL` accordingly.
- If `flutter_dotenv` doesn't load variables, confirm `await dotenv.load(fileName: ".env");` is called before usage (it is in `main.dart`).

## Notes & next steps

- `.env` is already listed in `.gitignore` and should not be committed.
- I added a `.env.example` with placeholders — copy it to `.env` and fill in your keys.
- If you want, I can also create a small script to validate required env vars at startup.

---

If you want any section expanded (setup for iOS build, CI config, backend API documentation generation, or a contributing checklist), tell me which area to expand and I will update `README.md` accordingly.

-- End of README
