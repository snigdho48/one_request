<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# one_request

## A simple all-in-one web request package for Flutter.

### Features
- Built on top of **dio**, **flutter_easyloading**, **either_dart**
- Type-safe, generic API: specify your expected response type
- Global configuration: base URL, headers, interceptors
- Per-request customization: interceptors, cancel tokens
- Retry logic for transient errors (with exponential backoff)
- Custom error handling and logging
- Fully customizable loading and error widgets
- Error message localization support
- **Offline support (caching)** for GET requests
- **Batch requests**: send multiple requests in parallel

---

## Usage

### 1. Global Setup

```dart
void main() async {
  // Configure loading UI and global options
  OneRequest.loadingconfig(
    backgroundColor: Colors.amber,
    indicator: const CircularProgressIndicator(),
    indicatorColor: Colors.red,
    progressColor: Colors.red,
    textColor: Colors.red,
    success: const Icon(Icons.check, color: Colors.green),
    error: const Icon(Icons.error, color: Colors.red),
    info: const Icon(Icons.info, color: Colors.blue),
  );

  // Set global base URL, headers, and interceptors (optional)
  OneRequest.configure(
    baseUrl: 'https://api.example.com',
    headers: {'Authorization': 'Bearer token'},
    interceptors: [/* your Dio interceptors */],
  );

  // Set custom error handler, logger, and widget builders (optional)
  OneRequest.setErrorHandler(
    handler: (body, status, url) => body['custom_message'] ?? 'Unknown error',
    logger: (error, stack) => print('Error: $error'),
  );
  LoadingStuff.setCustomBuilders(
    loadingBuilder: (context, status) => CircularProgressIndicator(),
    errorBuilder: (context, message) => Icon(Icons.error, color: Colors.red),
    localization: (msg) => 'Localized: $msg',
  );

  runApp(const MyApp());
}
```

### 2. MaterialApp Setup

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    builder: OneRequest.initLoading,
    title: 'Flutter Demo one_request',
    home: const MyHomePage(title: 'Flutter Demo Home Page'),
  );
}
```

### 3. Making Requests (Type-safe)

```dart
final request = OneRequest();
final result = await request.send<Map<String, dynamic>>(
  url: '/endpoint',
  method: RequestType.GET,
  header: {'test': 'test'},
  body: {'test': 'test'},
  formData: false,
  maxRedirects: 1,
  timeout: 60,
  contentType: ContentType.json,
  responsetype: ResponseType.json,
  innderData: false,
  loader: true,
  resultOverlay: true,
  cancelToken: CancelToken(), // optional
  interceptors: [/* per-request interceptors */],
  maxRetries: 2, // retry on network errors
  retryDelay: Duration(seconds: 2),
  useCache: true, // enable offline cache for GET
);

result.fold(
  (data) => print('Success: $data'),
  (error) => print('Error: $error'),
);
```

---

## Offline Support (Caching)
- To enable caching for GET requests, set `useCache: true` in your request.
- Cached responses are returned instantly if available.
- Clear the cache with:
```dart
OneRequest.clearCache();
```

---

## Batch Requests
Send multiple requests in parallel and get all results:
```dart
final batchResults = await OneRequest.batch<Map<String, dynamic>>([
  {
    'url': '/endpoint1',
    'method': RequestType.GET,
    'useCache': true,
  },
  {
    'url': '/endpoint2',
    'method': RequestType.POST,
    'body': {'foo': 'bar'},
  },
], maxRetries: 2, retryDelay: Duration(seconds: 1), exponentialBackoff: true);

for (final result in batchResults) {
  result.fold(
    (data) => print('Batch success: $data'),
    (error) => print('Batch error: $error'),
  );
}
```

---

## Advanced Retry/Backoff
- Use `maxRetries` and `retryDelay` in `send` or `batch` for automatic retries.
- Set `exponentialBackoff: true` in `batch` for exponential retry delays.

---

## Integration/Widget Testing
- See `test/one_request_integration_test.dart` for examples of widget/integration tests with mock servers and UI overlay checks.

---

## Customization
- Use `loadingconfig` and `setCustomBuilders` to fully control the loading and error UI.
- Use the localization callback to translate error messages.

---

## Summary Table
| Feature                | How to Use / Example                      |
|------------------------|-------------------------------------------|
| Type-safe requests     | `send<T>()`                               |
| Global config          | `OneRequest.configure(...)`               |
| Per-request config     | `send(..., interceptors: [...])`          |
| Retry logic            | `maxRetries`, `retryDelay`                |
| Exponential backoff    | `batch(..., exponentialBackoff: true)`    |
| Offline cache          | `useCache: true`, `clearCache()`          |
| Batch requests         | `OneRequest.batch([...])`                 |
| Custom error handling  | `setErrorHandler(...)`                    |
| Custom loading/error   | `setCustomBuilders(...)`                   |
| Localization           | `setCustomBuilders(localization: ...)`    |

---

## Troubleshooting & FAQ
- **Why is my GET request not cached?**
  - Make sure `useCache: true` and the request is a GET.
- **How do I clear the cache?**
  - Call `OneRequest.clearCache()`.
- **How do I batch requests with different types?**
  - Use `dynamic` as the generic type, or batch similar types together.
- **How do I test UI overlays?**
  - See the integration test for widget testing with overlays.
- **How do I handle custom error payloads?**
  - Use `setErrorHandler` to extract and format error messages.

---

## Testing
- See `/test` for example unit and integration tests.
- You can mock Dio and test your error handling logic.

## Contributing
Pull requests are welcome! Please open issues for bugs or feature requests.

---

## License
MIT
