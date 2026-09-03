# Changelog

## 3.0.0 - 2026-09-03

### Breaking changes

- Replaced `either_dart` with `dart_either` `^2.3.0`.
- `send` and `batch` now return `Either<String, T>`: **Left** is the error, **Right** is the data.
- `fold` uses named callbacks: `fold(ifLeft: ..., ifRight: ...)`.
- Use `getOrNull()` / `leftOrNull()` instead of `.left` / `.right`.
- If you treated `isLeft` as success, switch to `isRight`, or use `request<T>()` which throws `RequestException`.

### Added

- `OneRequest.request<T>()` — returns data or throws `RequestException`.
- `RequestException` and `RestErrorParser` for Django REST / JSON payloads (`error`, `detail`, `details`, `code`, `data`).
- `OneRequest.setAuth(...)` — optional JWT header + single-flight refresh on 401.
- `OneRequest.wrap()` — optional EasyLoading builder for `MaterialApp` / `GetMaterialApp`.
- `fileFromPath`, `fileFromByte`, `fileFormString`, `unwrapPayload`, `innerData`, `OneRequest.client`.
- `clearErrorHandler()` and additive `setErrorHandler` (`clearHandler` / `clearLogger`).
- Re-exports Dio, Either, and EasyLoading types from `package:one_request/one_request.dart` (do not add those packages yourself).
- Runs on Android, iOS, web, Windows, macOS, and Linux.

### Changed

- Default error handler is `RestErrorParser.handler` (replace or clear from the app).
- Global interceptors from `configure()` attach once on the shared Dio client.
- Loading UI is initialized only when you use `wrap` / `initLoading`, or when a request actually shows a loader/overlay.
- `file()` and `fileFromPath()` require `dart:io` (mobile/desktop). On web use `fileFromByte` or `fileFormString`.
- Dependencies: `dio` `^5.11.0`, `flutter_easyloading` `^4.0.2`, `dart_either` `^2.3.0`.
- SDK `>=3.6.0`, Flutter `>=3.27.0`.

## 2.3.0 - 2026-05-17

### Added

- Global request defaults on `configure()`: timeout, retries, retry delay, max redirects, cache.
- Error message controls: `sanitizeErrorMessages`, `maxErrorMessageLength`, `showStatusCodeInError`.

### Fixed

- GET cache returns before hitting the network.
- Error extraction no longer surfaces raw HTML payloads.
- Error overlays go through `LoadingStuff.showError(...)`.
- Replaced `print` with `debugPrint`.

### Changed

- Updated dependencies and SDK constraints.

## 2.2.1 - 2025-12-02

### Fixed

- Replaced deprecated `Matrix4.scale()` with `scaleByVector3()`.
- Missing type annotations on loading helpers.

### Changed

- Added `vector_math` for `Vector3`.
- `initLoading` is a `TransitionBuilder`.

## 2.2.0 - 2025-11-06

### Added

- Separate error and response loggers.
- Colored request / response / error logs.
- Global overlay on/off controls.
- Automatic redirect following.

### Changed

- Request logging turns on when any logger is enabled.

## Older versions

- 2.1.0 — retries, cache, batch requests.
- 2.0.x — error handling updates.
- 1.0.x — first stable API and overlays.
- 0.0.x — early releases.
