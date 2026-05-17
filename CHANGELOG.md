# Changelog

## [2.3.0] - 2026-05-17

### Added (2.3.0)

- Added global request defaults in `OneRequest.configure(...)`:
  - `defaultTimeoutSeconds`
  - `defaultMaxRetries`
  - `defaultRetryDelay`
  - `defaultMaxRedirects`
  - `defaultUseCache`
- Added error quality controls:
  - `sanitizeErrorMessages`
  - `maxErrorMessageLength`
  - `showStatusCodeInError`

### Fixed (2.3.0)

- Fixed GET cache behavior to return cached values before network calls.
- Improved error extraction to avoid exposing raw HTML/payload responses.
- Routed error overlays through `LoadingStuff.showError(...)` for consistent customization.
- Replaced direct `print(...)` calls with `debugPrint(...)`.
- Removed analyzer warnings from exhaustive switch defaults.

### Changed (2.3.0)

- Updated dependencies and SDK constraints.

## [2.2.1] - 2025-12-02

### Fixed (2.2.1)

- Fixed deprecated `Matrix4.scale()` usage by migrating to `scaleByVector3()`.
- Added missing type annotations for stronger static analysis.
- Fixed return type annotations for loading helper methods.

### Changed (2.2.1)

- Added `vector_math` dependency for `Vector3` support.
- Updated `initLoading` typing to `TransitionBuilder`.

## [2.2.0] - 2025-01-XX

### Added (2.2.0)

- Separate error/response logger controls.
- Enhanced colored request/response/error logging.
- Global overlay controls and settings introspection.
- Automatic redirect following.
- Improved fallback-based error message extraction.

### Changed (2.2.0)

- Logger settings now support independent toggles for error and response logs.
- Request logging auto-enables when any logger is enabled.

## Older versions

- 2.1.0: Core API, retries, cache, batch, docs, tests.
- 2.0.x: Error handling and dependency updates.
- 1.0.x: Initial stabilization and overlay options.
- 0.0.x: Early releases.
