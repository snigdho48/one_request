---
name: one-request-setup
description: Add one_request (only) and wire configure, setAuth, and OneRequest.wrap in the Flutter app.
---

# /one-request-setup

1. If `pubspec.yaml` has no `one_request`, run `flutter pub add one_request`.
2. Remove direct `dio`, `dart_either`, `either_dart`, and `flutter_easyloading` dependencies unless another package truly needs them.
3. Replace every `import 'package:dio/dio.dart'`, `import 'package:dart_either/dart_either.dart'`, and `import 'package:either_dart/either.dart'` with `import 'package:one_request/one_request.dart'`.
4. Create or update API setup **only for features the app wants**:
   - `OneRequest.configure(baseUrl: ...)` as needed
   - `OneRequest.setAuth(...)` only if the API uses JWT and the app wants the built-in interceptor
   - `builder: OneRequest.wrap(...)` only if the app wants EasyLoading
   - `setErrorHandler` / `clearErrorHandler` if the app does not want the default REST parser
5. Convert API methods to `OneRequest().request<T>(...)` **or** keep `send<T>()` if the app already folds `Either`. Do not force one style.
6. Run `flutter pub get` and `flutter analyze`.
