# Changelog

## 3.1.0 - 2026-09-21

### Added

- Optional WebSocket via `OneRequest.socket()` / `OneSocket`. Nothing connects until you call it. `configure(enableWebSocket: false)` hard-disables. JSON encode/decode on by default; `autoReconnect` off by default.
- Optional connectivity notices. Off until `setConnectivity()` or `configure(enableConnectivity: true)`. Default UI is snackbar; choose `ConnectivityUi.popover`, `banner`, `none`, or a custom `builder`. `clearConnectivity()` turns it off.
- `OneRequest.connectivityOverlay` for apps that skip `wrap()` / EasyLoading.

### Fixed

- Example app includes `flutter_lints` so `dart format .` no longer warns about an unresolved `analysis_options.yaml`.

### Changed

- README lists every optional HTTP, WebSocket, and connectivity knob; example app demonstrates toggling them.
- Compatibility script and CI also analyze the example and run socket/connectivity tests on Chrome (`flutter test -d chrome`).
- Raised three dependency lower bounds to the versions this package already resolves (`dart pub upgrade --tighten`).
- `configure(baseUrl:)` prefixes **relative** paths only. Absolute `http(s)://` / `ws(s)://` URLs are left alone so a second service is not concatenated onto the first.

### Added

- `OneRequest(baseUrl:, headers:)` for one client per backend. `openSocket()` uses that instance. `OneRequest.socket(baseUrl:)` overrides the default without changing HTTP config. Multiple `OneSocket` instances can stay open on different hosts.

## 3.0.0 - 2026-09-03

### Breaking changes

- `send` and `batch` now return `Either<String, T>`: **Left** is the error, **Right** is the data.
- `fold` uses named callbacks: `fold(ifLeft: ..., ifRight: ...)`.
- Use `getOrNull()` / `leftOrNull()` instead of `.left` / `.right`.
- If you treated `isLeft` as success, switch to `isRight`, or use `request<T>()` which throws `RequestException`.

### Added

- `OneRequest.request<T>()` — returns data or throws `RequestException`.
- `RequestException` and `RestErrorParser` for Django REST / JSON payloads (`error`, `detail`, `details`, `code`, `data`).
- `OneRequest.setAuth(...)` — optional JWT header + single-flight refresh on 401.
- `OneRequest.wrap()` — optional loading overlay builder for `MaterialApp` / `GetMaterialApp`.
- `fileFromPath`, `fileFromByte`, `fileFormString`, `unwrapPayload`, `innerData`, `OneRequest.client`.
- `clearErrorHandler()` and additive `setErrorHandler` (`clearHandler` / `clearLogger`).
- HTTP, socket, and overlay types come from `package:one_request/one_request.dart` — add only `one_request`.
- Runs on Android, iOS, web, Windows, macOS, and Linux.

### Changed

- Default error handler is `RestErrorParser.handler` (replace or clear from the app).
- Global interceptors from `configure()` attach once on the shared HTTP client.
- Loading UI is initialized only when you use `wrap` / `initLoading`, or when a request actually shows a loader/overlay.
- `file()` and `fileFromPath()` require `dart:io` (mobile/desktop). On web use `fileFromByte` or `fileFormString`.
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
