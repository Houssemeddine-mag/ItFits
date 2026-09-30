# ItFits — AI Interior Design

ItFits turns your phone into an interior designer. Capture any room as a 360°
photo sphere, draw its floor plan, pick a style, and let AI generate
photorealistic redesigns — all from one guided flow.

## Features

- **Guided 360° capture** — 12-stop tour (horizon → upper → lower → zenith →
  nadir) with a ghost-frame viewfinder, one-tap capture, and optional
  steady-hold auto-fire. Works fully offline.
- **On-device stitching** — frames are warped onto an equirectangular canvas
  using IMU poses and blended with edge feathering in a background isolate.
  Output carries standard GPano XMP metadata, so galleries and VR viewers
  recognize it as a 360° photo.
- **Interactive panorama viewer** — gyroscope + touch look-around of the
  captured sphere.
- **Floor-plan editor** — draw walls, doors, windows and dimensions, with an
  isometric 3D preview.
- **Style studio** — curated designer styles (Modern, Scandinavian,
  Industrial, Mid-Century, Bohemian, Coastal…) with matching palettes.
- **AI designer chat + generation** — conversational preferences, then
  AI-generated redesigns via OpenRouter (free tier) and Pollinations.ai.
- **Projects & history** — per-user project library backed by Cloud
  Firestore, recent-projects home feed, design detail pages.
- **Auth** — email/password, Google and Apple sign-in via Firebase Auth,
  with an offline demo mode when Firebase is unreachable.
- **Profile & settings** — editable profile, theme and notification
  preferences.

## Tech stack

| Layer      | Choice                                                     |
| ---------- | ---------------------------------------------------------- |
| Framework  | Flutter 3.47 / Dart 3.13 (Material 3)                      |
| State      | flutter_riverpod 3 (legacy `StateProvider` API)            |
| Navigation | go_router 18                                               |
| Backend    | Firebase Auth 6, Cloud Firestore 6, Firebase Core 4        |
| AI         | OpenRouter (chat), Pollinations.ai (image, no key needed)  |
| Capture    | camera, dchs_motion_sensors (rotation vector), wakelock    |
| Imaging    | image 4 (warp/blend), flutter_image_compress, image_picker |
| Models     | freezed + json_serializable (codegen)                      |

## Project structure

```
lib/
├── core/
│   ├── config/        # API keys / endpoints (env-driven)
│   ├── models/        # Freezed data models (project, user, style…)
│   ├── router/        # go_router routes + auth redirects
│   ├── services/      # Auth, projects, images, AI, Riverpod providers
│   └── theme/         # Material 3 theme (Google Fonts)
├── features/
│   ├── auth/          # Onboarding + sign-in screens
│   ├── capture/engine/# 360 engine: lattice math, orientation fusion,
│   │                    # offline stitcher + XMP injection
│   ├── create/        # Guided capture → panorama → floor plan →
│   │                    # style → AI chat → generation → result
│   ├── history/       # Project library + design details
│   ├── home/          # Home feed + bottom navigation shell
│   └── profile/       # Profile, settings, edit-profile
└── main.dart          # Firebase bootstrap + app entry
test/
└── sphere_math_test.dart  # Capture-engine unit tests
```

## Getting started

### Prerequisites

- Flutter **3.47.x** (stable) — `flutter doctor` should be green
- Android SDK with **Platform 37**, build-tools 36+, NDK **28.2.x**
- JDK 17+
- A physical Android device (the 360 capture needs a rear camera and
  motion sensors; emulators and desktops show a graceful fallback)
- `android/app/google-services.json` is already included for the
  `com.itfits.app` Firebase project

### Run

```bash
flutter pub get
flutter run -d <device-id>     # e.g. flutter run -d chrome, or a phone
```

Useful variants:

```bash
flutter analyze                 # static analysis (zero errors expected)
flutter test                    # capture-engine unit tests
flutter build apk --debug       # Android smoke build
```

### Regenerating models

```bash
dart run build_runner build --delete-conflicting-outputs
```

## The 360 capture pipeline

1. **Lattice** (`sphere_math.dart`) — 12 stops in tour order: 6 × horizon
   (60° steps), 2 × upper (+50°), 2 × lower (−50°), zenith, nadir.
2. **Pose tracking** (`orientation_service.dart`) — game rotation vector
   (gyro + accelerometer, magnetometer-free so indoor readings stay
   smooth), deltas measured from the latched start frame; gyro-magnitude
   gate for steadiness.
3. **Acquisition** (`room_scan_screen.dart`) — ghost-frame guidance, one-tap
   capture per stop, AE/AF locked from frame #1, full-res JPEGs spooled to
   a temp directory.
4. **Stitch** (`sphere_stitcher.dart`) — pose-driven equirectangular warp +
   feather blend in an isolate, JPEG encode, GPano XMP `APP1` injection.

## Configuration

| Key                | Where                                        | Notes                        |
| ------------------ | -------------------------------------------- | ---------------------------- |
| `OPENROUTER_API_KEY` | `--dart-define` at run/build time          | Enables AI chat; app degrades gracefully without it |
| Firebase           | `android/app/google-services.json`           | Included; without network the app runs in demo mode |
| Google Sign-In     | Firebase console OAuth clients               | v7 plugin API (`initialize()` + `authenticate()`) |

## Status & roadmap

Working today: guided capture → stitch → panorama review → floor plan →
style → AI chat → generation → result, with history and profile.

Planned: iOS capture parity, cloud photo backup, shareable design links,
contractor-ready export (dimensions + shopping list), onboarding polish.

## License

Proprietary — all rights reserved. Contact the project owner for licensing.
