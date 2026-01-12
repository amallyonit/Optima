# Copilot / AI Agent Instructions for Optima

Purpose: Quick, actionable guidance so AI coding agents become productive immediately in this Flutter codebase.

Quick setup (what to run)
- Install deps: `flutter pub get`
- Run on a device: `flutter run -d <device-id>` (e.g., `windows`, `chrome`, `emulator-5554`)
- Build Android APK: `flutter build apk --release`
- Run tests: `flutter test`

High-level architecture (big picture)
- Flutter multi-platform app (mobile, web, desktop). Entry: `lib/main.dart`.
- State: extensive use of `provider` with many `ChangeNotifierProvider`s registered in `main.dart`.
- Network: central URLs in `lib/api_helper.dart` (`ApiHelper.baseUrl`, `ApiHelper.warehouseUrl`). Many services POST/GET relative to these.
- Version check: `lib/versionservice.dart` posts to `${ApiHelper.baseUrl}getlatestversion` and drives update UI in `VersionCheckPage`.
- HTTP: `lib/http_override.dart` disables SSL verification for dev servers (see warning below).

Project-specific conventions & patterns
- Branding/assets: assets are referenced as `assets/images/${ApiHelper.projectName}/...`. To switch branding update `ApiHelper.projectName` (see `lib/api_helper.dart`) and ensure matching assets are declared in `pubspec.yaml`.
- Providers centralization: Add new `ChangeNotifier` classes and register them in the provider list inside `lib/main.dart`. Example provider class names follow `Lead*Provider`, `Finance*Provider`, `...Provider` patterns.
- Page organization: UI pages live under `lib/pages/` with subfolders per feature (e.g., `dashboardPages`, `monthlyScheduler`). When adding new pages follow that folder structure.
- Lead stages: files under `lib/leadstages/` (e.g., `stageoneentry.dart`) implement sequential entry flows. Keep naming consistent with existing stages.

Network, security and dev server notes
- Default production URLs are set in `lib/api_helper.dart`. For local development change `baseUrl` and/or `warehouseUrl` there.
- `lib/http_override.dart` sets `badCertificateCallback = true` to accept self-signed certs. This is convenient for dev but insecure — do not ship builds with this enabled.
- VersionService expects a JSON response with `Data[0].LatestVersion` (see `lib/versionservice.dart`). Keep that format if mocking version endpoints.

Platform & permissions quirks
- Permissions are enforced early in `VersionCheckPage` (`lib/main.dart`): location, storage (Android SDK <33), microphone. Code uses `permission_handler` and `device_info_plus`.
- Storage permission check uses Android SDK version: if SDK >= 33 storage check is skipped (uses scoped storage). See `_checkStoragePermission()` in `VersionCheckPage`.

Build & debug tips specific to this repo
- If changing assets/branding: update `lib/api_helper.dart` and the `assets:` block in `pubspec.yaml` to include the new `projectName` folder.
- To debug network issues, temporarily set `ApiHelper.baseUrl` to a local/dev server and run with `flutter run`; note `http_override.dart` may allow insecure connections (use with caution).
- Many UI screens reference `ApiHelper.projectName` inside `AssetImage` constructors — incorrect projectName will throw runtime asset not found errors.

Examples
- Change base URL for dev:
```dart
// lib/api_helper.dart
static const String baseUrl = 'http://10.0.0.100:3000/';
```

- Add provider pattern (example): register `MyNewFeatureProvider` in `main.dart` inside `MultiProvider.providers`.

Files to inspect when making changes
- `lib/main.dart` — app entry, provider registrations, permissions, and version check flow.
- `lib/api_helper.dart` — projectName and base URLs for all network calls.
- `lib/versionservice.dart` — expected version API contract.
- `lib/http_override.dart` — SSL acceptance behavior for HttpClient.
- `pubspec.yaml` — dependency overrides (notably `intl`) and asset/font lists.

Notes & cautions
- Do not modify files under `windows/flutter/ephemeral` or other platform plugin symlinks — they are generated.
- The codebase uses `dependency_overrides` for `intl` in `pubspec.yaml`; be cautious when upgrading packages that depend on `intl`.
- The wide provider registration list in `main.dart` is deliberate: adding/removing providers must be mirrored in imports and where their state is consumed.

If anything here is unclear or you want additional examples (e.g., adding a provider, mocking the version API, or safely removing `http_override` for production), tell me which topic to expand.
