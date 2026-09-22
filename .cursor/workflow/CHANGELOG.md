# Workflow changelog

## [Unreleased]

### Fixed — 2026-09-22

**Time:** 2026-09-22 12:04 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Give the example its own flutter_lints so `dart format .` can resolve analysis_options.yaml.

**Files:**
- `example/pubspec.yaml` — `flutter_lints` dev_dependency
- `example/analysis_options.yaml` — include flutter.yaml

**Impact:** none

### Added — 2026-09-22

**Time:** 2026-09-22 12:00 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Multiple HTTP/WebSocket services per app — instance baseUrl, socket baseUrl override, absolute URLs never prefixed.

**Files:**
- `lib/src/resolve_url.dart` — `resolveRequestUrl` / `isAbsoluteNetworkUrl`
- `lib/src/dio_request.dart` — `OneRequest(baseUrl, headers)`, `openSocket`, `socket(baseUrl:)`
- `README.md`, `example/lib/main.dart`, tests, flexibility/plugin docs

**Impact:** API

### Changed — 2026-09-22

**Time:** 2026-09-22 11:50 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Raise connectivity_plus lower bound to 7.1.0 so pana downgrade analysis recognizes ConnectivityResult.satellite.

**Files:**
- `pubspec.yaml` — `connectivity_plus: ^7.1.0`
- `tool/check_compatibility.ps1`, `.github/workflows/compatibility.yml` — Chrome via `-d chrome`

**Impact:** API / none

### Changed — 2026-09-21

**Time:** 2026-09-21 20:15 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Documented every public knob in README, expanded the Flutter example, and extended VM/Chrome compatibility (including example analyze).

**Files:**
- `README.md` — full configure / HTTP / socket / connectivity API
- `example/lib/main.dart`, `example/pubspec.yaml` — runnable demo
- `tool/check_compatibility.ps1`, `.github/workflows/compatibility.yml` — Chrome socket + connectivity tests
- `pubspec.yaml` — topics + description

**Impact:** none

### Added — 2026-09-21

**Time:** 2026-09-21 19:50 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Optional WebSocket client and optional connectivity_plus snackbar/popover/banner (all off or overridable).

**Files:**
- `lib/src/socket/` — `OneSocket` connect/send/listen/close, JSON, reconnect opt-in
- `lib/src/connectivity/` — watch + snackbar/popover/banner/custom/none
- `lib/src/dio_request.dart` — `socket()`, `setConnectivity()`, `wrap()` host
- `test/one_socket_test.dart`, `test/one_connectivity_test.dart`
- `README.md`, `CHANGELOG.md`, `cursor-plugin/`, `.cursor/rules/app-flexibility.mdc`

**Impact:** API / none

### Changed — 2026-09-03

**Time:** 2026-09-03 19:00 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Rewrote README and example for pub.dev — 3.0 API, no internal/CI notes.

**Files:**
- `README.md` — install, request/send, auth, platforms, 2.x migration
- `example/example.dart` — wrap(), request(), named fold, byte upload

**Impact:** none

### Changed — 2026-09-03

**Time:** 2026-09-03 18:35 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Path uploads (`file` / `fileFromPath`) only compile against dart:io. Web and WASM use byte/string uploads so every Flutter platform is supported.

**Files:**
- `lib/src/platform/io_types_io.dart` / `io_types_stub.dart` — fromFile only on native
- `README.md` — Platforms section
- `test/one_request_platform_test.dart` — web throws on fileFromPath

**Impact:** none

### Added — 2026-09-03

**Time:** 2026-09-03 18:00 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Platform-safe IO types so the package compiles on web; VM + Chrome compatibility tests and GitHub Action.

**Files:**
- `lib/src/platform/io_types*.dart` — dart:io vs web stubs
- `test/one_request_platform_test.dart` — fake-adapter send/request on VM and Chrome
- `tool/check_compatibility.ps1` — analyze + VM + Chrome
- `.github/workflows/compatibility.yml` — CI matrix
- `pubspec.yaml` — platforms: android/ios/web/windows/macos/linux

**Impact:** none

### Changed — 2026-09-03

**Time:** 2026-09-03 17:50 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Keep one_request modular — apps can turn off or replace overlays, error handler, auth, and loading UI. configure() no longer auto-themes EasyLoading.

**Files:**
- `lib/src/dio_request.dart` — additive setErrorHandler, clearErrorHandler, loading only when overlays run
- `.cursor/rules/app-flexibility.mdc` — always-on flexibility rule
- `cursor-plugin/rules/one-request.mdc` — do not force setAuth/wrap/request
- `README.md`, `CHANGELOG.md` — app-level control

**Impact:** API / none

### Changed — 2026-09-03

**Time:** 2026-09-03 17:30 (UTC+6)
**Author:** Cursor agent
**Issue:** n/a

**Summary:** Replaced unmaintained either_dart with dart_either 2.3.0; send/batch are now `Either<String, T>` (Left=error, Right=success). Version 3.0.0.

**Files:**
- `pubspec.yaml` — dart_either ^2.3.0, version 3.0.0
- `lib/one_request.dart` — re-export dart_either
- `lib/src/dio_request.dart` — `Either<String, T>`, named fold
- `test/`, `example/example.dart`, `README.md` — migration
- `cursor-plugin/` — also block dart_either extra installs

**Impact:** API / none

### Added — 2026-09-03

**Time:** 2026-09-03 17:20 (UTC+6)
**Author:** Cursor agent

**Summary:** one_request 2.4.0 — re-export dio/either, request()/setAuth/wrap, Cursor plugin that blocks extra pub add.

**Files:**
- `lib/one_request.dart` — re-export dio, either_dart, EasyLoading types
- `lib/src/model/request_exception.dart` — RequestException + RestErrorParser
- `lib/src/auth/auth_interceptor.dart` — JWT setAuth
- `lib/src/dio_request.dart` — request(), wrap(), shared interceptors
- `cursor-plugin/` — Cursor plugin (rules, skill, hook)
- `pubspec.yaml` — 2.4.0, dio 5.11.0, flutter_easyloading 4.0.2

**Impact:** API / none
