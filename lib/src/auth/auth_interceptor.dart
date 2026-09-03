import 'package:dio/dio.dart';

typedef TokenReader = Future<String?> Function();
typedef TokenWriter = Future<void> Function(String access, String refresh);

/// Bearer auth + single-flight refresh on 401.
///
/// Attach via [OneRequest.setAuth] — do not add `dio` to the app pubspec.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.getAccessToken,
    this.getRefreshToken,
    this.saveTokens,
    this.refreshPath = '/auth/token/refresh/',
    this.skipPathContains = const ['/auth/token'],
    this.headerName = 'Authorization',
    this.headerPrefix = 'Bearer ',
    this.onRefreshFailed,
    required Dio client,
  }) : _client = client;

  static const _retryExtra = 'one_request_auth_retry';

  final TokenReader getAccessToken;
  final TokenReader? getRefreshToken;
  final TokenWriter? saveTokens;
  final String refreshPath;
  final List<String> skipPathContains;
  final String headerName;
  final String headerPrefix;
  final Future<void> Function()? onRefreshFailed;
  final Dio _client;

  Future<String?>? _refreshInFlight;

  bool _shouldSkip(String path) {
    return skipPathContains.any(path.contains);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers[headerName] = '$headerPrefix$token';
      }
      handler.next(options);
    } catch (e, st) {
      handler.reject(
        DioException(requestOptions: options, error: e, stackTrace: st),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final options = err.requestOptions;
    final alreadyRetried = options.extra[_retryExtra] == true;
    final path = options.path;

    if (response?.statusCode != 401 || alreadyRetried || _shouldSkip(path)) {
      handler.next(err);
      return;
    }

    try {
      final access = await _refreshAccessTokenOnce();
      if (access == null || access.isEmpty) {
        handler.next(err);
        return;
      }

      options.headers[headerName] = '$headerPrefix$access';
      options.extra[_retryExtra] = true;
      final retry = await _client.fetch(options);
      handler.resolve(retry);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessTokenOnce() {
    return _refreshInFlight ??= () async {
      try {
        final refresh = await getRefreshToken?.call();
        if (refresh == null || refresh.isEmpty) {
          await onRefreshFailed?.call();
          return null;
        }

        final res = await _client.post(
          refreshPath,
          data: {'refresh': refresh},
        );
        final data = res.data is Map
            ? Map<String, dynamic>.from(res.data as Map)
            : <String, dynamic>{};
        final nested = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : data;
        final access =
            nested['access']?.toString() ?? data['access']?.toString() ?? '';
        if (access.isEmpty) {
          await onRefreshFailed?.call();
          return null;
        }
        final newRefresh = nested['refresh']?.toString() ??
            data['refresh']?.toString() ??
            refresh;
        await saveTokens?.call(access, newRefresh);
        return access;
      } catch (_) {
        await onRefreshFailed?.call();
        return null;
      } finally {
        _refreshInFlight = null;
      }
    }();
  }
}
