---
name: one-request
description: >-
  Use one_request as the only Flutter HTTP client. Apply when adding APIs,
  Dio, Either, interceptors, loading overlays, JWT refresh, or pubspec
  network dependencies. Never add dio, dart_either, or either_dart.
---

# one_request skill

## When to use

- Adding HTTP/API calls in a Flutter app
- Cursor is about to `flutter pub add dio`, `dart_either`, or `either_dart`
- JWT, interceptors, FormData, file upload, PDF/bytes download
- GetMaterialApp / EasyLoading builder setup

## Hard rules

- `flutter pub add one_request` only.
- Single import: `import 'package:one_request/one_request.dart';`
- Never `import 'package:dio/dio.dart'`, `package:dart_either/dart_either.dart`, or `package:either_dart/either.dart`.
- `ResponseType` is one_request's enum. Dio's type is hidden on purpose.

## Setup (once in main / api_setup)

```dart
void configureApiClient() {
  OneRequest.configure(
    baseUrl: 'https://api.example.com',
    headers: {'Accept': 'application/json'},
    enableLoader: false,
    enableErrorOverlay: false,
    enableSuccessOverlay: false,
    enableErrorLogger: kDebugMode,
    enableResponseLogger: kDebugMode,
    defaultTimeoutSeconds: 60,
    defaultMaxRetries: 1,
    defaultMaxRedirects: 5,
  );

  OneRequest.setAuth(
    getAccessToken: () => storage.read('access_token'),
    getRefreshToken: () => storage.read('refresh_token'),
    saveTokens: (access, refresh) async {
      await storage.write('access_token', access);
      await storage.write('refresh_token', refresh);
    },
    refreshPath: '/auth/token/refresh/',
    skipPathContains: const ['/auth/token'],
  );
}

// MaterialApp / GetMaterialApp
builder: OneRequest.wrap(),
// or compose banners:
builder: OneRequest.wrap((context, child) {
  return Stack(children: [child!, const OfflineBanner()]);
}),
```

Do not write a custom Dio `Interceptor` for Bearer tokens unless the app already has one it wants to keep. `setAuth` is an optional shortcut and already refreshes on 401. `clearAuth()` removes it.

Skip `setAuth`, `wrap()`, and `request()` if the consuming app does not want them. Per-request `loader: false` / `resultOverlay: false` and `configure(enableLoader: false, ...)` must keep working.

## Calls

```dart
final api = OneRequest();

final me = await api.request<Map<String, dynamic>>(
  url: '/auth/me/',
  method: RequestType.GET,
  loader: false,
  unwrap: true, // pull nested {data: ...}
);

try {
  final created = await api.request<Map<String, dynamic>>(
    url: '/orders/',
    method: RequestType.POST,
    body: {'payment_method': 'cod'},
    loader: true,
  );
} on RequestException catch (e) {
  // e.message, e.code, e.data, e.statusCode
}
```

`send<T>` returns `Either<String, T>` (`Left` = error, `Right` = success). Fold with named `ifLeft` / `ifRight`. Prefer `request<T>` in apps.

## Uploads and bytes

```dart
final file = await api.fileFromPath(path: path, filename: 'avatar.jpg');
await api.request<Map<String, dynamic>>(
  url: '/auth/me/avatar/',
  method: RequestType.POST,
  formData: true,
  body: {'avatar': file},
);

final pdf = await api.request<List<int>>(
  url: '/orders/$id/invoice/',
  method: RequestType.GET,
  responsetype: ResponseType.bytes,
  loader: false,
);
```

## Errors

Django REST payloads (`error`, `detail`, `details`, `code`, `data`) are parsed by default. Do not re-implement that handler unless the API is unusual.

## If analyze complains about dio

The app imported `package:dio/dio.dart`. Delete that import and use types from `one_request`. Do not add `dio:` to `pubspec.yaml`.
