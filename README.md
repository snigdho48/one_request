# one_request

HTTP for Flutter: one import, optional loading overlays, optional JWT refresh, and errors you can either **throw** or **fold**.

Works on **Android, iOS, web, Windows, macOS, and Linux**.

```yaml
dependencies:
  one_request: ^3.0.0
```

```dart
import 'package:one_request/one_request.dart';
```

Do **not** add `dio`, `dart_either`, or `flutter_easyloading`. Those packages are already inside `one_request` and are re-exported. `ResponseType` is this package’s enum (`json` / `bytes` / `stream` / `plain`).

---

## Quick start

Everything except the request itself is optional. Turn overlays, auth, and logging off from your app.

```dart
void main() {
  OneRequest.configure(
    baseUrl: 'https://api.example.com',
    enableErrorLogger: true,
    enableResponseLogger: true,
    enableLoader: true,
    enableErrorOverlay: false,
    enableSuccessOverlay: false,
  );

  runApp(MaterialApp(
    builder: OneRequest.wrap(),
    home: const HomePage(),
  ));
}
```

### `request` — data or `RequestException`

```dart
final api = OneRequest();

try {
  final data = await api.request<Map<String, dynamic>>(
    url: '/users/me',
    method: RequestType.GET,
    unwrap: true, // pull nested { "data": ... }
  );
} on RequestException catch (e) {
  debugPrint(e.message); // human-readable
  debugPrint(e.code);    // API `code` if present
}
```

### `send` — `Either<String, T>`

`Left` is the error string. `Right` is the data.

```dart
final result = await api.send<Map<String, dynamic>>(
  url: '/users/me',
  method: RequestType.GET,
);

result.fold(
  ifRight: (data) => debugPrint('ok $data'),
  ifLeft: (error) => debugPrint('error $error'),
);
```

---

## JWT (optional)

Skip this if you already attach headers yourself. `clearAuth()` removes it.

```dart
OneRequest.setAuth(
  getAccessToken: () => storage.read('access_token'),
  getRefreshToken: () => storage.read('refresh_token'),
  saveTokens: (access, refresh) async { /* persist */ },
  refreshPath: '/auth/token/refresh/',
  skipPathContains: const ['/auth/token'],
);
```

Compose EasyLoading with your own overlay:

```dart
GetMaterialApp(
  builder: OneRequest.wrap((context, child) {
    return Stack(children: [child!, const OfflineBanner()]);
  }),
);
```

---

## Uploads

Bytes work on **every** platform (including web):

```dart
final api = OneRequest();
await api.request<Map<String, dynamic>>(
  url: '/upload',
  method: RequestType.POST,
  formData: true,
  body: {
    'file': api.fileFromByte(filebyte: bytes),
  },
);
```

`file()` and `fileFromPath()` need `dart:io` (mobile/desktop). Guard with `hasDartIo` if you share code with web.

---

## Errors and overlays

Django-style bodies (`error`, `detail`, `details`, `code`, `data`) are parsed by default.

```dart
OneRequest.setErrorHandler(handler: myParser); // replace
OneRequest.clearErrorHandler();                // off
OneRequest.resetErrorHandler();                // package default

OneRequest.configure(
  enableLoader: false,
  enableErrorOverlay: false,
  enableSuccessOverlay: false,
  sanitizeErrorMessages: true,
  maxErrorMessageLength: 220,
);

await api.send(
  url: '/silent',
  method: RequestType.GET,
  loader: false,
  resultOverlay: false,
);
```

---

## Batch, cache, retries

```dart
final results = await OneRequest.batch<Map<String, dynamic>>([
  {'url': '/a', 'method': RequestType.GET, 'useCache': true},
  {'url': '/b', 'method': RequestType.POST, 'body': {'x': 1}},
], maxRetries: 2, exponentialBackoff: true);

OneRequest.clearCache();
```

Per-request: `maxRetries`, `retryDelay`, `useCache`, `timeout`, `header`, `cancelToken`, `interceptors`.

---

## Logging

Off by default. In debug:

```dart
OneRequest.configure(
  enableErrorLogger: true,    // 4xx / 5xx / exceptions
  enableResponseLogger: true, // 2xx / 3xx
);
```

---

## Migrating from 2.x

| 2.x (`either_dart`) | 3.x (`dart_either`) |
|---|---|
| `Either<T, String>` | `Either<String, T>` |
| `Left` = success | `Right` = success |
| `fold((data) {}, (error) {})` | `fold(ifRight: ..., ifLeft: ...)` |
| `.left` / `.right` | `getOrNull()` / `leftOrNull()` |

Or stop folding and use `request<T>()`.

---

## Example

See [`example/example.dart`](example/example.dart).

## License

GPL-3.0
