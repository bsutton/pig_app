# Pigation App

## Overview
Pigation is a Flutter app for controlling external lighting and irrigation
systems from a mobile device or browser. The Pigation server runs on a Raspberry
Pi, and the app can be compiled for Android, iOS, web, and desktop.

The app lets you configure GPIO pins on the Pi to control devices such as
lights and valves for irrigation. While the app can control any attached
device, the UI and workflows are tailored for irrigation and lighting.

Full documentation:
https://bsutton.gitbook.io/pigation/

Contributions are welcome. Please submit patches or PRs.

## Running
1. Ensure Flutter SDK 3.8+ is installed (see `pubspec.yaml`).
2. Install dependencies:
   `flutter pub get`
3. Set `SERVER_URL` (env or `.env`) to point at your `pig_server`.
4. Run the app:
   `flutter run`

Common targets:
`flutter run -d chrome` (web), `flutter run -d windows` (desktop)

## Build
Standard Flutter builds:
`flutter build apk`
`flutter build appbundle --release`
`flutter build web`
`flutter build macos` / `flutter build windows` / `flutter build linux`

Build helper (updates version, runs `flutter pub get`, builds):
`dart run tool/build.dart --build`

WebAssembly build:
`dart run tool/build.dart --wasm`

## Release
Android release bundle:
`dart run tool/build.dart --release`
This creates `hmb-<version>.aab` in the project root.

Note: `android/app/build.gradle.kts` currently signs release builds with the
debug key. For a real Play Store release, update the signing config to use your
release keystore (see `tool/linux_setup.dart` for keystore generation on Linux).

## Debugging / local dev
You can run both `pig_app` and `pig_server` on the same dev system.

1. Update the server config (e.g., `pig_server/config/config.yaml`) to use a
   port above 1024. Recommended: `1080`.
2. Point the app at the server by setting `SERVER_URL` to
   `http://localhost:1080` (via environment variable or `.env`).

Example VS Code configuration:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "pig_app",
      "cwd": "pig_app",
      "request": "launch",
      "type": "dart",
      "env": {
        "SERVER_URL": "http://localhost:1080"
      }
    }
  ]
}
```
