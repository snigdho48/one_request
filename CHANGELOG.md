## [2.2.1] - 2025-12-02
### Fixed
- Fixed deprecated `Matrix4.scale()` method by using `scaleByVector3()` for better compatibility
- Added missing type annotations throughout the codebase for better static analysis
- Fixed return type annotations for `loading()`, `loadingDismiss()`, and `initLoading` methods
- Fixed code formatting issues to match Dart formatter standards
- Improved package description to meet pub.dev requirements (50-180 characters)

### Changed
- Added `vector_math` as a direct dependency for `Vector3` support in progress indicators
- Updated `initLoading` return type to use `TransitionBuilder` for proper MaterialApp builder compatibility

### Technical
- All code now passes static analysis with no errors, warnings, or lint issues
- Package now achieves 160/160 pub.dev score points

---

## [2.2.0] - 2025-01-XX
### Added
- **Separate Error and Response Loggers** with independent control
  - `enableErrorLogger`: Logs errors (4xx, 5xx, exceptions) in red
  - `enableResponseLogger`: Logs successful responses (2xx, 3xx) in green/yellow
  - Request logging automatically enabled when any logger is enabled
  - New methods: `setErrorLoggerEnabled()`, `setResponseLoggerEnabled()`, `isErrorLoggerEnabled()`, `isResponseLoggerEnabled()`
- **Enhanced Colored API Logging** with full response display
  - Color-coded output: Green (success), Red (error), Yellow (warning/redirects), Blue (info)
  - Full JSON response display with proper formatting and indentation
  - No truncation - complete response data is shown
  - Line-by-line printing to avoid buffer limits
  - Request/response inspection with masked sensitive headers
  - Duration tracking and status code highlighting
  - Enable/disable via `configure(enableErrorLogger: true, enableResponseLogger: true)` or legacy `enableLogger: true`
- **Global overlay controls** for loading, error, and success overlays
  - `setOverlaySettings()` to control overlays globally
  - `getOverlaySettings()` to check current settings (includes logger states)
  - Per-request overlay settings still work (respects global settings)
- **Automatic redirect following** with configurable `maxRedirects`
  - Automatically follows 3xx redirects
  - Logs redirect information when response logger is enabled
  - Handles both relative and absolute redirect URLs
- Enhanced error message extraction with multiple fallback strategies
- Improved error handling to ensure non-empty error messages
- Warning and info logging methods with proper logger routing

### Changed
- Logger configuration now supports separate error and response loggers
- Response logger shows only successful responses (2xx, 3xx) - errors are handled by error logger
- Request logging is automatically enabled when any logger type is enabled
- Improved JSON formatting with proper indentation using `JsonEncoder.withIndent()`
- Response data is printed line-by-line to prevent truncation issues
- Error logger handles all error scenarios (4xx, 5xx, exceptions, timeouts)
- Updated `configure()` method to accept `enableErrorLogger` and `enableResponseLogger` parameters
- Legacy `enableLogger` parameter still works (enables both loggers for backward compatibility)

### Fixed
- Response logger now displays full response data without truncation
- Fixed empty error messages by adding comprehensive fallback strategies
- Redirect handling now properly follows 3xx status codes and logs them as responses
- Improved error message extraction from various response formats (Map, List, String)
- Fixed ANSI color code handling in console output
- Enhanced error message validation to ensure non-empty messages are always returned

---

## [2.1.0] - 2025-07-16
### Added
- Type-safe, generic API (`send<T>()`)
- PascalCase naming (`OneRequest`)
- Global configuration: base URL, headers, interceptors
- Per-request customization: interceptors, cancel tokens
- Retry logic for transient errors, with exponential backoff
- Custom error handler and logger support
- Fully customizable loading and error widgets
- Error message localization support
- **Offline support (caching)** for GET requests (`useCache` and `clearCache`)
- **Batch requests**: send multiple requests in parallel (`OneRequest.batch`)
- Integration/widget test support (see `test/one_request_integration_test.dart`)
- Improved documentation and usage examples
- Summary table and troubleshooting/FAQ in README
- Unit and integration tests for all features

### Changed
- All code samples and docs now use PascalCase and the new API
- API docs fully updated for new features
- Improved error handling and logging
- Updated dependencies

---


### - Fix Error Message Handeling more specifically

## 2.0.5

### - Fix Error Message Handeling

## 2.0.4

### - Add Patch For request

## 2.0.3

### - Update dependencies

## 2.0.2

### - Show Error Message Specifically send by the server on Right

## 2.0.1

### - Score Updated

## 2.0.0

### - Updated dependencies

### - Added Web support

## 1.0.9

### - Fix Error Handeling

## 1.0.8

### - Updated dependencies

## 1.0.7

### - Updated dependencies

## 1.0.6

### - Updated dependencies

## 1.0.5

### - Fix Some Issue

## 1.0.4

### - Fix ErrorMassage Handeling

### - added Option Loading and Result Status Overlay show or hide feature

### - Updated Dependencies

## 1.0.3

### - Updated Dependencies

## 1.0.2

### - Version updated

## 1.0.0

### - Version update

## 0.0.6

### - mirror bug fix

## 0.0.5

### - mirror bug fixing

## 0.0.4

### - Overlay loading added

### - Optimize code

## 0.0.3

### - Documentation added

### - File input added

## 0.0.2

### - Release adding inner json content check

## 0.0.1

### - initial release
