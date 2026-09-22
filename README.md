# one_request

HTTP, optional WebSockets, and optional connectivity notices for Flutter. One import. Every feature can be skipped, replaced, or turned off from the consuming app.

Works on **Android, iOS, web, Windows, macOS, and Linux**.

```yaml
dependencies:
  one_request: ^3.1.0
```

```dart
import 'package:one_request/one_request.dart';
```

Add only `one_request`. Import `package:one_request/one_request.dart` and use the types from there. `ResponseType` is this package’s enum (`json` / `bytes` / `stream` / `plain`).

| You can use | You can skip / turn off |
|---|---|
| `request<T>()` (throws) | Use `send<T>()` (`Either`) instead |
| `send<T>()` + `fold` | Use `request<T>()` instead |
| Loading overlay via `wrap()` | Own `MaterialApp.builder`; `enableLoader: false` |
| JWT `setAuth` | Own headers / interceptors; `clearAuth()` |
| WebSocket `socket()` | Don’t call it; or `enableWebSocket: false` |
| Connectivity snackbar / popover / banner | Don’t call `setConnectivity`; or `clearConnectivity()` / `ui: none` / custom `builder` |
| Default REST error parser | `setErrorHandler` / `clearErrorHandler()` |
| Logging | Off by default |
| Cache, retries, batch | Off / zero by default |

---

## Quick start

Everything except the request itself is optional.

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
  debugPrint(e.message);
  debugPrint(e.code);
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

## `configure` — every field optional

Omit a field to leave the current value unchanged. `resetConfig()` restores package defaults.

| Argument | Default | What it does |
|---|---|---|
| `baseUrl` | `null` | Default prefix for **relative** HTTP and `ws` paths. Absolute `http(s)://` / `ws(s)://` URLs are never prefixed. Per-service clients use `OneRequest(baseUrl: …)` instead. |
| `headers` | `null` | Global headers (per-call `header` wins) |
| `interceptors` | `null` | Replaces globally attached interceptors |
| `enableLoader` | `true` | Global loading overlay |
| `enableErrorOverlay` | `true` | Global error overlay |
| `enableSuccessOverlay` | `true` | Global success overlay |
| `enableLogger` | — | Legacy: both error + response logs |
| `enableErrorLogger` | `false` | 4xx / 5xx / exceptions |
| `enableResponseLogger` | `false` | 2xx / 3xx |
| `sanitizeErrorMessages` | `true` | Strip client noise from messages |
| `maxErrorMessageLength` | `220` | Truncate overlay / `Left` text |
| `showStatusCodeInError` | `false` | Prefix `[status]` on messages |
| `defaultTimeoutSeconds` | `60` | Per-request `timeout` overrides |
| `defaultMaxRetries` | `0` | Per-request `maxRetries` overrides |
| `defaultRetryDelay` | `1s` | Per-request `retryDelay` overrides |
| `defaultMaxRedirects` | `1` | Per-request `maxRedirects` overrides |
| `defaultUseCache` | `false` | GET memory cache; per-request `useCache` |
| `enableWebSocket` | `true` | Kill switch; nothing connects until `socket()` |
| `wsAutoReconnect` | `false` | Default for new sockets |
| `wsEncodeJson` | `true` | Encode `Map`/`List` as JSON strings |
| `wsDecodeJson` | `true` | Decode incoming `{...}` / `[...]` |
| `wsMaxReconnectAttempts` | `5` | `0` = unlimited when reconnect is on |
| `wsReconnectDelay` | `2s` | Delay between reconnects |
| `enableConnectivity` | `false` | Opt into connectivity notices |
| `connectivityUi` | `snackbar` | `snackbar` / `banner` / `popover` / `none` |
| `showOfflineNotice` | `true` | Show when going/staying offline |
| `showOnlineNotice` | `true` | Brief “back online” (snackbar) |
| `offlineMessage` | `No internet connection` | Copy |
| `onlineMessage` | `Back online` | Copy |
| `connectivityNoticeDuration` | `4s` | Online snack duration |

Helpers with the same knobs: `setOverlaySettings`, `setLoggerEnabled`, `setErrorLoggerEnabled`, `setResponseLoggerEnabled`, `getOverlaySettings`, `isLoggerEnabled`, `isErrorLoggerEnabled`, `isResponseLoggerEnabled`.

---

## Per-request HTTP

`send` and `request` accept:

| Argument | Notes |
|---|---|
| `url`, `method` | Required. `GET` / `POST` / `PUT` / `PATCH` / `DELETE` |
| `body`, `queryParameters` | JSON map, or `formData: true` |
| `header` | Merged over global headers |
| `contentType` | `json` / `stream` / `bytes` / `text` |
| `responsetype` | `json` / `bytes` / `stream` / `plain` |
| `timeout`, `maxRedirects` | Seconds / count |
| `maxRetries`, `retryDelay` | Transient timeouts |
| `useCache` | GET only, in-memory |
| `loader`, `resultOverlay` | AND with global overlay flags |
| `innerData` / `innderData` | Nested `{ "data": ... }` |
| `unwrap` | `request()` only; same envelope |
| `cancelToken` | `CancelToken` from the one_request import |
| `interceptors` | Extra interceptors for this call |
| `formData` | `FormData.fromMap` |

Shared client: `OneRequest.client` (prefer `send` / `request` / `setAuth`). `OneRequest.clearCache()` dumps GET cache.

---

## Multiple services (multiple instances)

`configure(baseUrl:)` is only the **default** prefix. One app can talk to several hosts.

- **HTTP:** `OneRequest(baseUrl: 'https://shop.example.com')` vs `OneRequest(baseUrl: 'https://pay.example.com')`. Each instance prefixes its own relative paths. Omit `baseUrl` on the constructor to keep using `configure`.
- **Sockets:** every `socket()` / `openSocket()` call is a **new** `OneSocket`. Hold as many as you need. Pass `wss://other.host/path` (or `https://…`) to ignore HTTP `baseUrl`, or pass `baseUrl:` on that call / use `client.openSocket`.
- **Absolute URLs** on `send` / `request` / `socket` always win — they are not concatenated onto any base.

```dart
final shop = OneRequest(baseUrl: 'https://shop.example.com');
final pay = OneRequest(baseUrl: 'https://pay.example.com');

await shop.request<Map<String, dynamic>>(
  url: '/orders',
  method: RequestType.GET,
);
await pay.send<Map<String, dynamic>>(
  url: '/charge',
  method: RequestType.POST,
  body: {'amount': 10},
);

// Same HTTP default, different live host:
final chat = OneRequest.socket(url: '/ws/chat'); // → configure/instance base
final live = OneRequest.socket(url: 'wss://live.example.com/feed');
final alerts = pay.openSocket(url: '/ws/alerts'); // pay's base → wss://pay…/ws/alerts

await Future.wait([chat.ready, live.ready, alerts.ready]);
```

`OneRequest.socket(url: '/ws', baseUrl: 'https://realtime.example.com')` overrides without creating an HTTP client.

```dart
await api.request<List<int>>(
  url: '/invoice.pdf',
  method: RequestType.GET,
  responsetype: ResponseType.bytes,
  loader: false,
  resultOverlay: false,
  timeout: 30,
  maxRetries: 1,
);
```

---

## JWT (optional)

Skip this if you already attach headers. `clearAuth()` removes it.

```dart
OneRequest.setAuth(
  getAccessToken: () => storage.read('access_token'),
  getRefreshToken: () => storage.read('refresh_token'),
  saveTokens: (access, refresh) async { /* persist */ },
  refreshPath: '/auth/token/refresh/',
  skipPathContains: const ['/auth/token'],
  headerName: 'Authorization',
  headerPrefix: 'Bearer ',
  onRefreshFailed: () async { /* logout */ },
);
```

---

## Loading UI (optional)

```dart
MaterialApp(builder: OneRequest.wrap()); // loading overlay + connectivity host
OneRequest.initLoading;                  // same as wrap()
OneRequest.wrap((context, child) {       // compose your overlay
  return Stack(children: [child!, const MyBanner()]);
});
OneRequest.loadingconfig(                // colors / indicator / mask
  progressColor: Colors.white,
  backgroundColor: Colors.black,
);
LoadingStuff.setCustomBuilders(          // replace loader / error widgets
  loadingBuilder: (context, status) => const Spinner(),
  errorBuilder: (context, message) => Text(message),
  localization: (msg) => msg,
);
OneRequest.loadingWidget(status: 'Saving');
await OneRequest.dismissLoading;
```

Skip `wrap()` if you do not want the built-in loading overlay. Connectivity default UI then needs `connectivityOverlay` (below) or your own `onChanged` / `builder`.

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

`file()` and `fileFromPath()` need `dart:io` (mobile/desktop). Guard with `hasDartIo` if you share code with web. `fileFormString` is also available.

---

## Errors and overlays

Django-style bodies (`error`, `detail`, `details`, `code`, `data`) are parsed by default.

```dart
OneRequest.setErrorHandler(handler: myParser); // replace
OneRequest.setErrorHandler(logger: myLog);     // keep parser
OneRequest.clearErrorHandler();                // off
OneRequest.resetErrorHandler();                // package default

await api.send(
  url: '/silent',
  method: RequestType.GET,
  loader: false,
  resultOverlay: false,
);
```

`RequestException` fields: `message`, `code`, `data`, `statusCode`, `url`. Helpers: `RestErrorParser.handler`, `RestErrorParser.messageFromBody`, `unwrapPayload`.

---

## Batch, cache, retries

```dart
final results = await OneRequest.batch<Map<String, dynamic>>([
  {'url': '/a', 'method': RequestType.GET, 'useCache': true},
  {'url': '/b', 'method': RequestType.POST, 'body': {'x': 1}},
], maxRetries: 2, exponentialBackoff: true);

OneRequest.clearCache();
```

---

## WebSocket (optional)

Nothing connects until you call `socket()`. Each call is a separate connection (different URL allowed). Hard-disable with `configure(enableWebSocket: false)` — then `socket()` throws. Defaults: JSON on, reconnect **off**.

```dart
final socket = OneRequest.socket(
  url: '/ws/chat', // or wss://other.host/path — not tied to HTTP baseUrl
  baseUrl: 'https://realtime.example.com', // optional; else instance / configure
  headers: {'X-Client': 'app'},
  protocols: const ['json'],
  pingInterval: const Duration(seconds: 30), // native only
  connectTimeout: const Duration(seconds: 10),
  autoReconnect: false,
  maxReconnectAttempts: 5,
  reconnectDelay: const Duration(seconds: 2),
  encodeJson: true,
  decodeJson: true,
  onMessage: (event) {},
  onState: (state) {},
  onError: (error, stack) {},
);

await socket.ready;
socket.send({'type': 'hello'}); // Map/List → JSON if encodeJson
socket.send('plain');
socket.messages.listen((event) {});
socket.states.listen((state) {});
debugPrint('${socket.state} ${socket.uri}');
await socket.close(1000, 'bye');
```

Also: `client.openSocket(...)` (uses that instance’s `baseUrl` / `headers`), `OneSocket.connect(...)`, `OneRequest.isWebSocketEnabled()`, `resolveSocketUri`, `resolveRequestUrl`. Extra headers are sent on Android / iOS / desktop; browsers cannot set WebSocket headers.

`SocketState`: `disconnected` / `connecting` / `connected` / `reconnecting` / `closing`.

---

## Connectivity (optional, off by default)

Off until you opt in. Interface up/down (not a full internet ping). Default UI is a snackbar; pick popover, banner, none, or a builder.

```dart
OneRequest.setConnectivity(); // snackbar + “Back online”
OneRequest.setConnectivity(ui: ConnectivityUi.popover);
OneRequest.setConnectivity(ui: ConnectivityUi.banner);
OneRequest.setConnectivity(
  ui: ConnectivityUi.none,
  onChanged: (status) => debugPrint('online=${status.online}'),
);
OneRequest.setConnectivity(
  showOffline: true,
  showOnline: false,
  offlineMessage: 'No internet',
  onlineMessage: 'Back online',
  noticeDuration: const Duration(seconds: 3),
  builder: (context, status, child) {
    if (status.online) return child;
    return Stack(children: [child, const Text('offline')]);
  },
);
OneRequest.setConnectivity(enabled: false);
OneRequest.clearConnectivity();
```

Read without UI: `isConnectivityEnabled()`, `connectivityUi`, `connectivityStatus`, `connectivity` (stream), `checkConnectivity()`.

Host widgets:

```dart
MaterialApp(builder: OneRequest.wrap()); // loading overlay + notices
MaterialApp(
  builder: (context, child) =>
      OneRequest.connectivityOverlay(child: child!),
);
```

`ConnectivityStatus.online` and `.connections` (`NetworkKind`: wifi, mobile, ethernet, vpn, bluetooth, satellite, other, none).

---

## Logging

Off by default.

```dart
OneRequest.configure(
  enableErrorLogger: true,
  enableResponseLogger: true,
);
OneRequest.logger; // logging package Logger
```

---

## Re-exported types

From `package:one_request/one_request.dart` you already have `CancelToken`, `Interceptor`, `FormData`, `MultipartFile`, `DioException`, `Either` / `Left` / `Right`, `EasyLoading` / `EasyLoadingMaskType`, plus this package’s `RequestType`, `ResponseType`, `ContentType`, `RequestException`, `OneSocket`, `ConnectivityUi`, `resolveSocketUri`, `resolveRequestUrl`. Add only `one_request` — do not add extra HTTP, socket, or connectivity packages.

---

## Platforms

Declared in `pubspec.yaml`: Android, iOS, web, Windows, macOS, Linux. HTTP and WebSocket run on all of them. Path uploads (`file` / `fileFromPath`) are native-only. Compatibility gates: `tool/check_compatibility.ps1` (analyze + VM tests + Chrome).

---

## Migrating from 2.x

| 2.x | 3.x |
|---|---|
| `Either<T, String>` | `Either<String, T>` |
| `Left` = success | `Right` = success |
| `fold((data) {}, (error) {})` | `fold(ifRight: ..., ifLeft: ...)` |
| `.left` / `.right` | `getOrNull()` / `leftOrNull()` |

Or stop folding and use `request<T>()`.

---

## Example

See [`example/lib/main.dart`](example/lib/main.dart) — HTTP, WebSocket, and connectivity UI toggles.

## License

GPL-3.0
