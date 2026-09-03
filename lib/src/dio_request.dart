import 'dart:core';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:dart_either/dart_either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:logging/logging.dart';
import 'auth/auth_interceptor.dart';
import 'model/error.dart';
import 'model/request_exception.dart';
import 'platform/io_types.dart';
import 'resourses/types.dart';
import 'resourses/utils.dart';

typedef ErrorHandler = String Function(
    Map<String, dynamic> errorBody, int? statusCode, String? url);
typedef ErrorLogger = void Function(Object error, StackTrace? stackTrace);

// ignore: camel_case_types
class OneRequest {
  static String? _baseUrl;
  static Map<String, String>? _globalHeaders;

  // Global overlay settings
  static bool _globalLoaderEnabled = true;
  static bool _globalErrorOverlayEnabled = true;
  static bool _globalSuccessOverlayEnabled = true;

  // Global logger settings
  static bool _loggerEnabled = false; // Disabled by default for production
  static bool _errorLoggerEnabled = false; // Error logger (disabled by default)
  static bool _responseLoggerEnabled =
      false; // Response logger (disabled by default)
  static bool _sanitizeErrorMessages = true;
  static int _maxErrorMessageLength = 220;
  static bool _showStatusCodeInError = false;

  // Global request defaults
  static int _defaultTimeoutSeconds = 60;
  static int _defaultMaxRetries = 0;
  static Duration _defaultRetryDelay = const Duration(seconds: 1);
  static int _defaultMaxRedirects = 1;
  static bool _defaultUseCache = false;

  static final dio.Dio _dio = dio.Dio();
  static final Logger _logger = Logger('OneRequest');
  static AuthInterceptor? _authInterceptor;
  static bool _loadingConfigured = false;
  static final List<dio.Interceptor> _attachedGlobalInterceptors = [];

  /// Shared Dio client. Prefer [send]/[request]/[setAuth] over using this directly.
  static dio.Dio get client => _dio;

  /// Configure global options for all requests. Every argument is optional;
  /// omit a field to leave the current value unchanged. Overlays, logging,
  /// retries, and cache can all be turned off from the consuming app.
  static void configure({
    String? baseUrl,
    Map<String, String>? headers,
    List<dio.Interceptor>? interceptors,
    bool? enableLoader,
    bool? enableErrorOverlay,
    bool? enableSuccessOverlay,
    bool? enableLogger,
    bool? enableErrorLogger,
    bool? enableResponseLogger,
    bool? sanitizeErrorMessages,
    int? maxErrorMessageLength,
    bool? showStatusCodeInError,
    int? defaultTimeoutSeconds,
    int? defaultMaxRetries,
    Duration? defaultRetryDelay,
    int? defaultMaxRedirects,
    bool? defaultUseCache,
  }) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
    }
    if (headers != null) {
      _globalHeaders = headers;
    }
    if (interceptors != null) {
      for (final interceptor in _attachedGlobalInterceptors) {
        _dio.interceptors.remove(interceptor);
      }
      _attachedGlobalInterceptors.clear();
      for (final interceptor in interceptors) {
        if (!_dio.interceptors.contains(interceptor)) {
          _dio.interceptors.add(interceptor);
          _attachedGlobalInterceptors.add(interceptor);
        }
      }
    }
    if (enableLoader != null) {
      _globalLoaderEnabled = enableLoader;
    }
    if (enableErrorOverlay != null) {
      _globalErrorOverlayEnabled = enableErrorOverlay;
    }
    if (enableSuccessOverlay != null) {
      _globalSuccessOverlayEnabled = enableSuccessOverlay;
    }
    // Handle logger configuration
    if (enableLogger != null) {
      // Legacy support: enableLogger enables both error and response logging
      _errorLoggerEnabled = enableLogger;
      _responseLoggerEnabled = enableLogger;
    }
    if (enableErrorLogger != null) {
      _errorLoggerEnabled = enableErrorLogger;
    }
    if (enableResponseLogger != null) {
      _responseLoggerEnabled = enableResponseLogger;
    }
    if (sanitizeErrorMessages != null) {
      _sanitizeErrorMessages = sanitizeErrorMessages;
    }
    if (maxErrorMessageLength != null && maxErrorMessageLength > 0) {
      _maxErrorMessageLength = maxErrorMessageLength;
    }
    if (showStatusCodeInError != null) {
      _showStatusCodeInError = showStatusCodeInError;
    }
    if (defaultTimeoutSeconds != null && defaultTimeoutSeconds > 0) {
      _defaultTimeoutSeconds = defaultTimeoutSeconds;
    }
    if (defaultMaxRetries != null && defaultMaxRetries >= 0) {
      _defaultMaxRetries = defaultMaxRetries;
    }
    if (defaultRetryDelay != null) {
      _defaultRetryDelay = defaultRetryDelay;
    }
    if (defaultMaxRedirects != null && defaultMaxRedirects > 0) {
      _defaultMaxRedirects = defaultMaxRedirects;
    }
    if (defaultUseCache != null) {
      _defaultUseCache = defaultUseCache;
    }
    _updateLoggerEnabled();
  }

  /// Update _loggerEnabled based on error/response logger states
  /// Request logging is automatically enabled if any logger is enabled
  static void _updateLoggerEnabled() {
    _loggerEnabled = _errorLoggerEnabled || _responseLoggerEnabled;
    // We use debugPrint to avoid lint issues and preserve console readability.
  }

  /// Set global overlay settings
  static void setOverlaySettings({
    bool? enableLoader,
    bool? enableErrorOverlay,
    bool? enableSuccessOverlay,
  }) {
    if (enableLoader != null) {
      _globalLoaderEnabled = enableLoader;
    }
    if (enableErrorOverlay != null) {
      _globalErrorOverlayEnabled = enableErrorOverlay;
    }
    if (enableSuccessOverlay != null) {
      _globalSuccessOverlayEnabled = enableSuccessOverlay;
    }
  }

  /// Get current overlay settings
  static Map<String, bool> getOverlaySettings() {
    return {
      'loader': _globalLoaderEnabled,
      'errorOverlay': _globalErrorOverlayEnabled,
      'successOverlay': _globalSuccessOverlayEnabled,
      'logger': _loggerEnabled,
      'errorLogger': _errorLoggerEnabled,
      'responseLogger': _responseLoggerEnabled,
      'sanitizeErrorMessages': _sanitizeErrorMessages,
      'showStatusCodeInError': _showStatusCodeInError,
      'defaultUseCache': _defaultUseCache,
    };
  }

  /// Enable or disable logger globally (legacy method - enables both error and response logging)
  /// When enabled, all API requests, responses, and errors will be logged with colored output
  static void setLoggerEnabled(bool enabled) {
    _errorLoggerEnabled = enabled;
    _responseLoggerEnabled = enabled;
    _updateLoggerEnabled();
  }

  /// Enable or disable error logger
  /// When enabled, errors will be logged with colored output
  static void setErrorLoggerEnabled(bool enabled) {
    _errorLoggerEnabled = enabled;
    _updateLoggerEnabled();
  }

  /// Enable or disable response logger
  /// When enabled, all API responses (successful and errors) will be logged with colored output
  static void setResponseLoggerEnabled(bool enabled) {
    _responseLoggerEnabled = enabled;
    _updateLoggerEnabled();
  }

  /// Check if logger is enabled (any type)
  static bool isLoggerEnabled() {
    return _loggerEnabled;
  }

  /// Check if error logger is enabled
  static bool isErrorLoggerEnabled() {
    return _errorLoggerEnabled;
  }

  /// Check if response logger is enabled
  static bool isResponseLoggerEnabled() {
    return _responseLoggerEnabled;
  }

  /// Get the logger instance for custom logging
  static Logger get logger => _logger;

  /// Reset global configuration.
  static void resetConfig() {
    _baseUrl = null;
    _globalHeaders = null;
    for (final interceptor in _attachedGlobalInterceptors) {
      _dio.interceptors.remove(interceptor);
    }
    _attachedGlobalInterceptors.clear();
    _loadingConfigured = false;
    _globalLoaderEnabled = true;
    _globalErrorOverlayEnabled = true;
    _globalSuccessOverlayEnabled = true;
    _loggerEnabled = false;
    _errorLoggerEnabled = false;
    _responseLoggerEnabled = false;
    _sanitizeErrorMessages = true;
    _maxErrorMessageLength = 220;
    _showStatusCodeInError = false;
    _defaultTimeoutSeconds = 60;
    _defaultMaxRetries = 0;
    _defaultRetryDelay = const Duration(seconds: 1);
    _defaultMaxRedirects = 1;
    _defaultUseCache = false;
    clearAuth();
  }

  // ignore: non_constant_identifier_names
  // initializer
  static Future<void>? get dismissLoading => LoadingStuff.loadingDismiss();
  static TransitionBuilder get initLoading => wrap();

  /// Composes EasyLoading with an extra overlay (GetMaterialApp, banners, etc).
  /// Optional — skip this and use your own `builder` if you do not want EasyLoading.
  ///
  /// ```dart
  /// GetMaterialApp(
  ///   builder: OneRequest.wrap((context, child) => Stack(
  ///     children: [child!, const OfflineBanner()],
  ///   )),
  /// )
  /// ```
  static TransitionBuilder wrap([TransitionBuilder? overlay]) {
    _ensureLoadingConfig();
    final loading = LoadingStuff.initLoading;
    if (overlay == null) return loading;
    return (context, child) => overlay(context, loading(context, child));
  }

  static void _ensureLoadingConfig() {
    if (_loadingConfigured) return;
    loadingconfig();
  }

  /// Returns the loading function
  static Future<void>? Function({
    String? status,
    Color? color,
    Widget? indicator,
    BuildContext? context,
  }) get loading => LoadingStuff.loading;
  // loading widget
  /// Displays a loading widget with an optional status message, color, and indicator widget.
  ///
  /// The [status] parameter is an optional message to display below the loading indicator.
  /// The [color] parameter is an optional color to use for the loading indicator.
  /// The [indicator] parameter is an optional widget to use as the loading indicator.
  static void loadingWidget({
    String? status,
    Color? color,
    Widget? indicator,
  }) =>
      LoadingStuff.loading(
        status: status,
        color: color,
        indicator: indicator,
      );
  // loading config
  /// Configures the loading widget for the DioRequest class.
  ///
  /// This method takes in several optional parameters that allow you to customize
  /// the appearance of the loading widget. You can specify the indicator widget,
  /// progress color, background color, indicator color, text color, success widget,
  /// error widget, and info widget.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// DioRequest.loadingconfig(
  ///   indicator: CircularProgressIndicator(),
  ///   progressColor: Colors.blue,
  ///   backgroundColor: Colors.white,
  ///   indicatorColor: Colors.red,
  ///   textColor: Colors.black,
  ///   success: Icon(Icons.check),
  ///   error: Icon(Icons.error),
  ///   info: Icon(Icons.info),
  /// );
  /// ```
  static void loadingconfig({
    Widget? indicator,
    Color? progressColor,
    Color? backgroundColor,
    Color? indicatorColor,
    Color? textColor,
    Widget? success,
    Widget? error,
    Widget? info,
    double? radius,
    double? fontSize,
    double? progressWidth,
    double? indicatorSize,
    EdgeInsetsGeometry? contentPadding,
    EasyLoadingMaskType? maskType,
    Color? maskColor,
  }) {
    _loadingConfigured = true;
    LoadingStuff.configLoad(
      indicator: indicator,
      progressColor: progressColor,
      backgroundColor: backgroundColor,
      indicatorColor: indicatorColor,
      textColor: textColor,
      success: success,
      error: error,
      info: info,
      radius: radius,
      fontSize: fontSize,
      progressWidth: progressWidth,
      indicatorSize: indicatorSize,
      contentPadding: contentPadding,
      maskType: maskType,
      maskColor: maskColor,
    );
  }

  // filefromByte function
  /// Returns a [dio.MultipartFile] object from a list of bytes.
  ///
  /// The [filebyte] parameter is a required list of bytes that represents the file.
  ///
  /// Example usage:
  /// ```dart
  /// final fileBytes = await File('path/to/file').readAsBytes();
  /// final multipartFile = dioRequest.fileFromByte(filebyte: fileBytes);
  /// ```
  dio.MultipartFile fileFromByte({required List<int> filebyte}) =>
      dio.MultipartFile.fromBytes(
        filebyte,
      );
  // filefromString function
  /// Returns a [dio.MultipartFile] object created from a string.
  ///
  /// The [filestring] parameter is a required string that represents the file content.
  ///
  /// Example usage:
  /// ```dart
  /// final file = dioRequest.fileFormString(filestring: 'file content');
  /// ```
  dio.MultipartFile fileFormString({required String filestring}) =>
      dio.MultipartFile.fromString(
        filestring,
      );

  /// Native (`dart:io`) only — Android, iOS, Windows, macOS, Linux.
  /// On web use [fileFromByte] or [fileFormString].
  dio.MultipartFile file({required File file, String? filename}) =>
      multipartFromFile(file, filename: filename);

  /// Native (`dart:io`) only. On web use [fileFromByte].
  Future<dio.MultipartFile> fileFromPath({
    required String path,
    String? filename,
  }) =>
      multipartFromPath(path, filename: filename);

  /// Attach JWT access tokens and optional refresh-on-401.
  /// Optional — skip this and pass headers/interceptors from the app instead.
  ///
  /// Skip adding `dio` to pubspec — interceptors, [CancelToken], and
  /// [MultipartFile] are re-exported from this package.
  static void setAuth({
    required TokenReader getAccessToken,
    TokenReader? getRefreshToken,
    TokenWriter? saveTokens,
    String refreshPath = '/auth/token/refresh/',
    List<String> skipPathContains = const ['/auth/token'],
    String headerName = 'Authorization',
    String headerPrefix = 'Bearer ',
    Future<void> Function()? onRefreshFailed,
  }) {
    clearAuth();
    _authInterceptor = AuthInterceptor(
      getAccessToken: getAccessToken,
      getRefreshToken: getRefreshToken,
      saveTokens: saveTokens,
      refreshPath: refreshPath,
      skipPathContains: skipPathContains,
      headerName: headerName,
      headerPrefix: headerPrefix,
      onRefreshFailed: onRefreshFailed,
      client: _dio,
    );
    _dio.interceptors.add(_authInterceptor!);
  }

  /// Remove the interceptor installed by [setAuth].
  static void clearAuth() {
    if (_authInterceptor != null) {
      _dio.interceptors.remove(_authInterceptor);
      _authInterceptor = null;
    }
  }

  /// Optional error handler and logger. Defaults to [RestErrorParser.handler].
  /// The app can replace, wrap, or clear these at any time.
  static ErrorHandler? _customErrorHandler = RestErrorParser.handler;
  static ErrorLogger? _customLogger;

  /// Current error handler, or `null` if the app cleared it.
  static ErrorHandler? get errorHandler => _customErrorHandler;

  /// Current error logger, or `null` if none is set.
  static ErrorLogger? get errorLogger => _customLogger;

  /// Replace only the pieces you pass. Omitted arguments stay as they are.
  ///
  /// ```dart
  /// OneRequest.setErrorHandler(handler: myParser); // keep logger
  /// OneRequest.setErrorHandler(logger: myLog);     // keep parser
  /// OneRequest.setErrorHandler(clearHandler: true); // built-in extraction only
  /// ```
  static void setErrorHandler({
    ErrorHandler? handler,
    ErrorLogger? logger,
    bool clearHandler = false,
    bool clearLogger = false,
  }) {
    if (clearHandler) {
      _customErrorHandler = null;
    } else if (handler != null) {
      _customErrorHandler = handler;
    }
    if (clearLogger) {
      _customLogger = null;
    } else if (logger != null) {
      _customLogger = logger;
    }
  }

  /// Restore the built-in REST parser and clear the logger.
  static void resetErrorHandler() {
    _customErrorHandler = RestErrorParser.handler;
    _customLogger = null;
  }

  /// Turn off the custom parser and logger. Payload extraction still runs.
  static void clearErrorHandler() {
    _customErrorHandler = null;
    _customLogger = null;
  }

  // Simple in-memory cache for GET requests
  static final Map<String, dynamic> _cache = {};

  /// Clear the in-memory cache
  static void clearCache() => _cache.clear();

  // send request function constructor
  /// Sends an HTTP request with the given parameters and returns a [Future] that
  /// completes with an [Either] of error [String] (`Left`) or response data (`Right`).
  ///
  /// The [body] parameter is an optional map of key-value pairs to include in the
  /// request body. The [queryParameters] parameter is an optional map of key-value
  /// pairs to include in the request URL query string. The [formData] parameter
  /// specifies whether to send the request as form data. The [responsetype]
  /// parameter specifies the expected response type. The [url] parameter is the
  /// URL to send the request to. The [method] parameter is the HTTP method to use.
  /// The [header] parameter is an optional map of key-value pairs to include in
  /// the request headers. The [maxRedirects] parameter specifies the maximum
  /// number of redirects to follow. The [contentType] parameter specifies the
  /// content type of the request body. The [timeout] parameter specifies the
  /// number of seconds to wait for a response before timing out. The [innderData]
  /// parameter specifies whether to include the response data in the returned
  /// [Either] object.
  Future<Either<String, T>> send<T extends Object?>({
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formData = false,
    ResponseType responsetype = ResponseType.json,
    required String url,
    required RequestType method,
    Map<String, String>? header,
    int? maxRedirects,
    ContentType contentType = ContentType.json,
    int? timeout,
    bool innderData = false,
    bool innerData = false,
    bool loader = true,
    bool resultOverlay = true,
    dio.CancelToken? cancelToken,
    List<dio.Interceptor>? interceptors,
    int? maxRetries,
    Duration? retryDelay,
    bool? useCache,
  }) =>
      _httpequest<T>(
        body: body,
        queryParameters: queryParameters,
        url: url,
        formData: formData,
        method: method,
        header: header,
        maxRedirects: maxRedirects,
        timeout: timeout,
        responsetype: responsetype,
        contentType: contentType,
        innderData: innderData || innerData,
        loader: loader,
        resultOverlay: resultOverlay,
        cancelToken: cancelToken,
        interceptors: interceptors,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
        useCache: useCache,
      );

  /// Same as [send], but unwraps [Either]: returns data or throws [RequestException].
  ///
  /// This is the API used in production apps so callers do not fold every call.
  /// Set [innerData] to pull the nested `data` field from `{data: ...}` envelopes.
  Future<T> request<T extends Object?>({
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formData = false,
    ResponseType responsetype = ResponseType.json,
    required String url,
    required RequestType method,
    Map<String, String>? header,
    int? maxRedirects,
    ContentType contentType = ContentType.json,
    int? timeout,
    bool innderData = false,
    bool innerData = false,
    bool unwrap = false,
    bool loader = true,
    bool resultOverlay = true,
    dio.CancelToken? cancelToken,
    List<dio.Interceptor>? interceptors,
    int? maxRetries,
    Duration? retryDelay,
    bool? useCache,
  }) async {
    final result = await send<T>(
      body: body,
      queryParameters: queryParameters,
      formData: formData,
      responsetype: responsetype,
      url: url,
      method: method,
      header: header,
      maxRedirects: maxRedirects,
      contentType: contentType,
      timeout: timeout,
      innderData: innderData,
      innerData: innerData,
      loader: loader,
      resultOverlay: resultOverlay,
      cancelToken: cancelToken,
      interceptors: interceptors,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      useCache: useCache,
    );
    return result.fold(
      ifLeft: (error) => throw RequestException.fromClient(error),
      ifRight: (data) {
        if (unwrap) {
          return unwrapPayload(data) as T;
        }
        return data;
      },
    );
  }

  // main request function
  /// Sends an HTTP request using Dio package.
  ///
  /// [body] is the request body.
  ///
  /// [queryParameters] is the query parameters of the request.
  ///
  /// [formData] is a boolean value indicating whether the request is a form data or not.
  ///
  /// [responsetype] is the response type of the request.
  ///
  /// [url] is the URL of the request.
  ///
  /// [method] is the HTTP method of the request.
  ///
  /// [header] is the header of the request.
  ///
  /// [maxRedirects] is the maximum number of redirects to follow.
  ///
  /// [contentType] is the content type of the request.
  ///
  /// [timeout] is the timeout duration of the request.
  ///
  /// [options] is the options of the request.
  ///
  /// [innderData] is a boolean value indicating whether to return the inner data of the response or not.
  ///
  /// Returns a [Future] of [Either] of dynamic and [CustomExceptionHandlers].
  // ANSI color codes for terminal output
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _gray = '\x1B[90m';
  static const String _white = '\x1B[37m';

  // Helper to mask sensitive headers for logging
  static Map<String, String> _maskSensitiveHeaders(
      Map<String, String> headers) {
    final Map<String, String> masked = Map<String, String>.from(headers);
    if (masked.containsKey('Authorization')) {
      final auth = masked['Authorization']!;
      if (auth.length > 20) {
        masked['Authorization'] = '${auth.substring(0, 20)}...';
      }
    }
    return masked;
  }

  // Helper to format request/response for logging with colors
  static void _logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
    bool formData = false,
  }) {
    // Auto-enable request logging if any logger is enabled
    if (!_loggerEnabled) return;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    buffer.writeln(
        '$_bold$_blue📤 ONE_REQUEST:$_reset $_bold$_white$method$_reset $_cyan$url$_reset');
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      buffer.writeln('$_yellow📋 Query Parameters:$_reset');
      queryParameters.forEach((key, value) {
        buffer.writeln('$_gray   $key:$_reset $_white$value$_reset');
      });
    }

    if (headers != null && headers.isNotEmpty) {
      final maskedHeaders = _maskSensitiveHeaders(headers);
      buffer.writeln('$_yellow📨 Headers:$_reset');
      maskedHeaders.forEach((key, value) {
        buffer.writeln('$_gray   $key:$_reset $_white$value$_reset');
      });
    }

    if (body != null && body.isNotEmpty) {
      buffer.writeln('$_yellow📦 Request Body:$_reset');
      if (formData) {
        buffer.writeln('$_gray   [FormData] ${body.length} fields$_reset');
        // Don't print form data fields as they might contain large base64 images
      } else {
        final String bodyStr = body.toString();
        if (bodyStr.length > 500) {
          buffer.writeln(
              '$_gray   ${bodyStr.substring(0, 500)}... (truncated)$_reset');
        } else {
          buffer.writeln('$_gray   $bodyStr$_reset');
        }
      }
    }
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');

    // Print directly to preserve colors without logging package formatting
    debugPrint(buffer.toString());
  }

  static void _logResponse({
    required int? statusCode,
    required String? statusMessage,
    dynamic data,
    required String url,
    required Duration duration,
  }) {
    // Only log if response logger is enabled AND it's not an error (errors are handled by error logger)
    // Response logger shows successful responses (2xx, 3xx) only
    if (!_responseLoggerEnabled) return;

    // Skip error responses (4xx, 5xx) - they are handled by error logger
    if (statusCode != null && statusCode >= 400) {
      return; // Don't log errors here, error logger will handle them
    }

    // Determine color based on status code
    String statusColor = _green; // Success (2xx)
    String statusIcon = '✅';
    if (statusCode != null) {
      if (statusCode >= 300 && statusCode < 400) {
        statusColor = _yellow; // Redirect (3xx)
        statusIcon = '⚠️';
      }
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    buffer.writeln(
        '$_bold$_green📥 ONE_REQUEST RESPONSE:$_reset $_cyan$url$_reset');
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    buffer.writeln(
        '$_magenta⏱️  Duration:$_reset $_white${duration.inMilliseconds}ms$_reset');
    buffer.writeln(
        '$_magenta📊 Status:$_reset $statusColor$statusIcon $statusCode${statusMessage != null ? ' $statusMessage' : ''}$_reset');

    if (data != null) {
      buffer.writeln('$_yellow📦 Response Data:$_reset');

      // Format data nicely based on type
      String formattedData = '';
      try {
        if (data is Map || data is List) {
          // Use jsonEncode for proper JSON formatting
          const encoder = JsonEncoder.withIndent('  ');
          formattedData = encoder.convert(data);
        } else if (data is String) {
          // Try to parse as JSON for formatting, fallback to string
          try {
            final dynamic decoded = jsonDecode(data);
            const encoder = JsonEncoder.withIndent('  ');
            formattedData = encoder.convert(decoded);
          } catch (_) {
            formattedData = data;
          }
        } else {
          formattedData = data.toString();
        }
      } catch (e) {
        // Fallback to toString if formatting fails
        formattedData = data.toString();
      }

      // Print header first
      debugPrint(buffer.toString());
      buffer.clear();

      // Split into lines and print each line separately to avoid buffer issues
      final List<String> lines = formattedData.split('\n');
      for (final line in lines) {
        // Print each line immediately to avoid truncation
        debugPrint('$_gray   $line$_reset');
      }

      // Print footer
      debugPrint(
          '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    } else {
      buffer.writeln('$_gray   (empty response)$_reset');
      buffer.writeln(
          '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
      // Print directly to preserve colors without logging package formatting
      debugPrint(buffer.toString());
    }
  }

  static void _logError({
    required String error,
    required String url,
    int? statusCode,
  }) {
    // Only log if error logger is enabled
    if (!_errorLoggerEnabled) return;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    buffer.writeln('$_bold$_red❌ ONE_REQUEST ERROR:$_reset $_cyan$url$_reset');
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    if (statusCode != null) {
      buffer.writeln('$_yellow📊 Status Code:$_reset $_red$statusCode$_reset');
    }
    buffer.writeln('$_red💥 Error:$_reset $_white$error$_reset');
    buffer.writeln(
        '$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');

    // Print directly to preserve colors without logging package formatting
    debugPrint(buffer.toString());
  }

  static void _logWarning({
    required String message,
    required String url,
  }) {
    // Warnings are part of error logging
    if (!_errorLoggerEnabled) return;

    final String formattedMessage =
        '$_yellow⚠️  WARNING:$_reset $_cyan$url$_reset\n$_yellow   $message$_reset';
    // Print directly to preserve colors
    debugPrint(formattedMessage);
  }

  static void _logInfo({
    required String message,
    String? url,
  }) {
    // Info messages are part of response logging
    if (!_responseLoggerEnabled) return;

    final String formattedMessage = url != null
        ? '$_blueℹ️  INFO:$_reset $_cyan$url$_reset\n$_blue   $message$_reset'
        : '$_blueℹ️  INFO:$_reset\n$_blue   $message$_reset';
    // Print directly to preserve colors
    debugPrint(formattedMessage);
  }

  String _finalizeErrorMessage(String message, {int? statusCode}) {
    String sanitized = message.trim();
    if (sanitized.isEmpty) {
      sanitized = 'An unexpected error occurred.';
    }

    if (_sanitizeErrorMessages) {
      sanitized = sanitized
          .replaceFirst(RegExp(r'^DioException(?:\s*\[[^\]]+\])?:\s*'), '')
          .replaceAll(RegExp(r'\s+'), ' ');
      if (sanitized.contains('\n')) {
        sanitized = sanitized.split('\n').first.trim();
      }
    }

    if (sanitized.length > _maxErrorMessageLength) {
      sanitized = '${sanitized.substring(0, _maxErrorMessageLength)}...';
    }

    if (_showStatusCodeInError && statusCode != null) {
      sanitized = '[$statusCode] $sanitized';
    }
    return sanitized;
  }

  Future<Either<String, T>> _httpequest<T extends Object?>({
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool formData = false,
    ResponseType responsetype = ResponseType.json,
    required String url,
    required RequestType method,
    Map<String, String>? header,
    int? maxRedirects,
    ContentType contentType = ContentType.json,
    int? timeout,
    dio.Options? options,
    bool innderData = false,
    bool loader = true,
    bool resultOverlay = true,
    dio.CancelToken? cancelToken,
    List<dio.Interceptor>? interceptors,
    int? maxRetries,
    Duration? retryDelay,
    bool? useCache,
  }) async {
    final startTime = DateTime.now();
    final r = _dio;
    final int effectiveTimeout = timeout ?? _defaultTimeoutSeconds;
    final int effectiveMaxRetries = maxRetries ?? _defaultMaxRetries;
    final Duration effectiveRetryDelay = retryDelay ?? _defaultRetryDelay;
    final int effectiveMaxRedirects = maxRedirects ?? _defaultMaxRedirects;
    final bool effectiveUseCache = useCache ?? _defaultUseCache;

    // Apply global config
    if (_baseUrl != null) {
      url = _baseUrl! + url;
    }

    // Merge headers: global headers first, then per-request headers (per-request overrides global)
    Map<String, String> finalHeaders = {};
    if (_globalHeaders != null) {
      finalHeaders.addAll(_globalHeaders!);
    }
    if (header != null) {
      finalHeaders.addAll(header); // Per-request headers override global
    }

    // Set default headers if none provided
    if (finalHeaders.isEmpty) {
      finalHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    } else {
      // Ensure Content-Type and Accept are set if not provided
      finalHeaders.putIfAbsent('Content-Type', () => 'application/json');
      finalHeaders.putIfAbsent('Accept', () => 'application/json');
    }

    // Log request
    _logRequest(
      method: method.value,
      url: url,
      headers: finalHeaders,
      queryParameters: queryParameters,
      body: body,
      formData: formData,
    );

    final allInterceptors = <dio.Interceptor>[...?interceptors];
    final addedInterceptors = <dio.Interceptor>[];
    if (allInterceptors.isNotEmpty) {
      for (final interceptor in allInterceptors) {
        if (!r.interceptors.contains(interceptor)) {
          r.interceptors.add(interceptor);
          addedInterceptors.add(interceptor);
        }
      }
    }

    final bool isGet = method == RequestType.GET;
    final String? cacheKey =
        isGet ? _buildCacheKey(url, queryParameters) : null;
    if (effectiveUseCache &&
        isGet &&
        cacheKey != null &&
        _cache.containsKey(cacheKey)) {
      final dynamic cached = _cache[cacheKey];
      return Right(cached as T);
    }

    // Loader / overlay only if the app left them on (global AND per-request).
    final shouldShowLoader = loader && _globalLoaderEnabled;
    final shouldShowOverlay = resultOverlay &&
        (_globalErrorOverlayEnabled || _globalSuccessOverlayEnabled);
    if (shouldShowLoader || shouldShowOverlay) {
      _ensureLoadingConfig();
    }
    if (shouldShowLoader) {
      LoadingStuff.loading();
    }

    int attempt = 0;
    try {
      while (true) {
        try {
          final dio.Response response = await r
              .request(
            url,
            data: formData && body != null ? dio.FormData.fromMap(body) : body,
            queryParameters: queryParameters,
            options: options ??
                dio.Options(
                  contentType: contentType.value,
                  responseType: responsetype.value,
                  followRedirects: effectiveMaxRedirects != 1,
                  method: method.value,
                  headers: finalHeaders,
                  maxRedirects: effectiveMaxRedirects,
                  validateStatus: (status) => true,
                ),
            cancelToken: cancelToken,
          )
              .timeout(
            Duration(seconds: effectiveTimeout),
            onTimeout: () {
              _logError(
                error: 'Request timeout after ${effectiveTimeout}s',
                url: url,
                statusCode: null,
              );
              throw ApiNotRespondingException('Request timeout', url);
            },
          );

          final duration = DateTime.now().difference(startTime);

          if (shouldShowLoader) {
            EasyLoading.dismiss();
          }

          // Success responses
          if ([200, 201, 202, 203, 204].contains(response.statusCode)) {
            final dynamic responseJson = response.data;

            // Log successful response - pass all data types
            _logResponse(
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              data:
                  responseJson, // Pass the actual response data (can be Map, List, String, etc.)
              url: url,
              duration: duration,
            );

            if (innderData) {
              try {
                if (responseJson is Map &&
                    responseJson['data'] != null &&
                    responseJson['data'] != '') {
                  if (effectiveUseCache && isGet && cacheKey != null) {
                    _cache[cacheKey] = responseJson['data'];
                  }
                  return Right(responseJson['data'] as T);
                } else {
                  if (resultOverlay &&
                      _globalSuccessOverlayEnabled &&
                      responseJson is Map &&
                      responseJson['message'] != null) {
                    EasyLoading.showSuccess(responseJson['message'].toString());
                  }
                  return Left(responseJson.toString());
                }
              } catch (e) {
                final msg =
                    CustomExceptionHandlers(error: e).getExceptionString();
                _logError(
                  error: msg,
                  url: url,
                  statusCode: response.statusCode,
                );
                if (resultOverlay && _globalErrorOverlayEnabled) {
                  LoadingStuff.showError(msg);
                }
                return Left(msg);
              }
            }
            if (resultOverlay && _globalSuccessOverlayEnabled) {
              EasyLoading.showSuccess(
                  response.statusMessage?.toString() ?? 'Success');
            }
            if (effectiveUseCache && isGet && cacheKey != null) {
              _cache[cacheKey] = responseJson;
            }
            return Right(responseJson as T);
          } else {
            // Handle non-2xx responses (3xx redirects, 4xx/5xx errors)
            String errorMsg;

            // Handle redirects (3xx status codes) - these are logged as responses, not errors
            if (response.statusCode != null &&
                response.statusCode! >= 300 &&
                response.statusCode! < 400) {
              // Log redirect as a response (3xx are part of response logging)
              _logResponse(
                statusCode: response.statusCode,
                statusMessage: response.statusMessage,
                data: response.data, // Pass the actual response data
                url: url,
                duration: duration,
              );

              final String? location = response.headers.value('location') ??
                  response.headers.value('Location');
              if (location != null) {
                _logInfo(
                    message: 'Redirect detected: $url → $location', url: url);
                // Try to follow redirect by making a new request
                if (effectiveMaxRedirects > 1 &&
                    attempt < effectiveMaxRedirects) {
                  _logInfo(
                      message: 'Following redirect to: $location',
                      url: location);
                  // Update URL and retry
                  url = Uri.parse(url).resolve(location).toString();
                  attempt++;
                  await Future.delayed(const Duration(milliseconds: 100));
                  continue;
                } else {
                  errorMsg =
                      'Redirect not followed. Please check URL: $url (Status: ${response.statusCode})';
                }
              } else {
                errorMsg =
                    'Redirect ${response.statusCode} but no location header found';
              }
            } else if (_customErrorHandler != null &&
                response.data is Map<String, dynamic>) {
              final customMsg = _customErrorHandler!(
                  response.data as Map<String, dynamic>,
                  response.statusCode,
                  url);
              // Ensure custom error handler doesn't return empty string
              errorMsg = (customMsg.trim().isNotEmpty)
                  ? customMsg.trim()
                  : 'Request failed with status ${response.statusCode}';
            } else {
              final extractedMsg = _extractErrorMessage(response.data);
              if (extractedMsg != null && extractedMsg.trim().isNotEmpty) {
                errorMsg = extractedMsg.trim();
              } else if (response.statusMessage != null &&
                  response.statusMessage!.trim().isNotEmpty) {
                errorMsg = response.statusMessage!.trim();
              } else {
                // Fallback error message based on status code
                if (response.statusCode == 401) {
                  errorMsg = 'Unauthorized. Please login again.';
                } else if (response.statusCode == 403) {
                  errorMsg = 'Access forbidden. You do not have permission.';
                } else if (response.statusCode == 404) {
                  errorMsg = 'Resource not found.';
                } else if (response.statusCode == 500) {
                  errorMsg = 'Server error. Please try again later.';
                } else {
                  errorMsg =
                      'Request failed with status ${response.statusCode}';
                }
              }
            }

            errorMsg = _finalizeErrorMessage(errorMsg,
                statusCode: response.statusCode);

            // Log error response
            _logError(
              error: errorMsg,
              url: url,
              statusCode: response.statusCode,
            );

            if (resultOverlay && _globalErrorOverlayEnabled) {
              LoadingStuff.showError(errorMsg);
            }
            return Left(errorMsg);
          }
        } on dio.DioException catch (e) {
          if (shouldShowLoader) EasyLoading.dismiss();
          String msg;
          bool shouldRetry = false;
          if (e.type == dio.DioExceptionType.connectionTimeout ||
              e.type == dio.DioExceptionType.sendTimeout ||
              e.type == dio.DioExceptionType.receiveTimeout) {
            msg = CustomExceptionHandlers(
                    error: ApiNotRespondingException('Request timeout', url))
                .getExceptionString();
            shouldRetry = attempt < effectiveMaxRetries;
            msg = _finalizeErrorMessage(msg);
            _logError(
              error: msg,
              url: url,
              statusCode: null,
            );
          } else if (e.type == dio.DioExceptionType.badResponse) {
            if (_customErrorHandler != null &&
                e.response?.data is Map<String, dynamic>) {
              final customMsg = _customErrorHandler!(
                  e.response!.data as Map<String, dynamic>,
                  e.response?.statusCode,
                  url);
              // Ensure custom error handler doesn't return empty string
              msg = (customMsg.trim().isNotEmpty)
                  ? customMsg.trim()
                  : 'Request failed (Status: ${e.response?.statusCode ?? 'unknown'})';
            } else {
              final extractedMsg = _extractErrorMessage(e.response?.data);
              if (extractedMsg != null && extractedMsg.trim().isNotEmpty) {
                msg = extractedMsg.trim();
              } else {
                final defaultMsg = (e.message?.trim().isNotEmpty == true)
                    ? e.message!.trim()
                    : 'Bad request';
                msg = CustomExceptionHandlers(
                        error: BadRequestException(defaultMsg, url))
                    .getExceptionString();
              }
            }
            // Ensure error message is not empty
            if (msg.trim().isEmpty) {
              msg =
                  'Request failed (Status: ${e.response?.statusCode ?? 'unknown'})';
            }
            msg =
                _finalizeErrorMessage(msg, statusCode: e.response?.statusCode);
            _logError(
              error: msg,
              url: url,
              statusCode: e.response?.statusCode,
            );
          } else if (e.type == dio.DioExceptionType.cancel) {
            msg = 'Request was cancelled.';
            msg = _finalizeErrorMessage(msg);
            _logError(
              error: msg,
              url: url,
              statusCode: null,
            );
          } else {
            msg = CustomExceptionHandlers(
                    error:
                        FetchDataException(e.message ?? 'Network error', url))
                .getExceptionString();
            // Ensure error message is not empty
            if (msg.isEmpty) {
              msg =
                  'Unable to connect to server. Please check your connection.';
            }
            msg = _finalizeErrorMessage(msg);
            _logError(
              error: msg,
              url: url,
              statusCode: null,
            );
          }
          if (_customLogger != null) {
            _customLogger!(e, e.stackTrace);
          }
          if (shouldRetry) {
            attempt++;
            _logWarning(
                message:
                    'Retrying request (attempt $attempt/$effectiveMaxRetries)...',
                url: url);
            await Future.delayed(effectiveRetryDelay);
            continue;
          }
          if (resultOverlay && _globalErrorOverlayEnabled) {
            LoadingStuff.showError(msg);
          }
          return Left(msg);
        } on SocketException catch (e) {
          if (shouldShowLoader) EasyLoading.dismiss();
          var msg = CustomExceptionHandlers(error: e).getExceptionString();
          // Ensure error message is not empty
          if (msg.isEmpty) {
            msg =
                'Network error: Unable to connect to server. Please check your internet connection.';
          }
          msg = _finalizeErrorMessage(msg);
          _logError(
            error: msg,
            url: url,
            statusCode: null,
          );
          if (_customLogger != null) {
            _customLogger!(e, null);
          }
          if (resultOverlay && _globalErrorOverlayEnabled) {
            LoadingStuff.showError(msg);
          }
          return Left(msg);
        } on AppException catch (e) {
          if (shouldShowLoader) EasyLoading.dismiss();
          var msg = CustomExceptionHandlers(error: e).getExceptionString();
          // Ensure error message is not empty
          if (msg.isEmpty) {
            msg = 'An error occurred while processing your request.';
          }
          msg = _finalizeErrorMessage(msg);
          _logError(
            error: msg,
            url: url,
            statusCode: null,
          );
          if (_customLogger != null) {
            _customLogger!(e, null);
          }
          if (resultOverlay && _globalErrorOverlayEnabled) {
            LoadingStuff.showError(msg);
          }
          return Left(msg);
        } catch (e, stack) {
          if (shouldShowLoader) EasyLoading.dismiss();
          var msg = CustomExceptionHandlers(error: e).getExceptionString();
          // Ensure error message is not empty
          if (msg.isEmpty) {
            msg = 'An unexpected error occurred: ${e.toString()}';
          }
          msg = _finalizeErrorMessage(msg);
          _logError(
            error: msg,
            url: url,
            statusCode: null,
          );
          if (_customLogger != null) {
            _customLogger!(e, stack);
          }
          if (resultOverlay && _globalErrorOverlayEnabled) {
            LoadingStuff.showError(msg);
          }
          return Left(msg);
        }
      }
    } finally {
      for (final interceptor in addedInterceptors) {
        r.interceptors.remove(interceptor);
      }
    }
  }

  /// Batch request support: send multiple requests in parallel.
  /// Each item in [requests] is a map of parameters for the send method.
  /// Returns a list of results in the same order.
  /// Optionally, set [maxRetries] and [retryDelay] for exponential backoff on transient errors.
  static Future<List<Either<String, T>>> batch<T extends Object?>(
    List<Map<String, dynamic>> requests, {
    int maxRetries = 0,
    Duration retryDelay = const Duration(seconds: 1),
    bool exponentialBackoff = false,
  }) async {
    Future<Either<String, T>> runWithRetry(Map<String, dynamic> params) async {
      int attempt = 0;
      Duration delay = retryDelay;
      while (true) {
        try {
          return await OneRequest().send<T>(
            // Spread the params map into named arguments
            // This requires the params map to use the same keys as send()
            // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
            body: params['body'],
            queryParameters: params['queryParameters'],
            formData: params['formData'] ?? false,
            responsetype: params['responsetype'] ?? ResponseType.json,
            url: params['url'],
            method: params['method'],
            header: params['header'],
            maxRedirects: params['maxRedirects'] ?? 1,
            contentType: params['contentType'] ?? ContentType.json,
            timeout: params['timeout'] ?? 60,
            innderData: params['innderData'] ?? false,
            loader: params['loader'] ?? true,
            resultOverlay: params['resultOverlay'] ?? true,
            cancelToken: params['cancelToken'],
            interceptors: params['interceptors'],
            maxRetries: params['maxRetries'] ?? maxRetries,
            retryDelay: params['retryDelay'] ?? retryDelay,
            useCache: params['useCache'] ?? false,
          );
        } catch (e) {
          if (attempt < maxRetries) {
            await Future.delayed(delay);
            attempt++;
            if (exponentialBackoff) {
              delay *= 2;
            }
            continue;
          }
          return Left(e.toString());
        }
      }
    }

    return Future.wait(requests.map(runWithRetry));
  }

  // Helper to extract error message from various response formats
  String? _extractErrorMessage(dynamic data) => RestErrorParser.fromData(data);

  // Helper to build a cache key from URL and query params
  String _buildCacheKey(String url, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return url;
    final sorted = Map.fromEntries(
        query.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return '$url?${sorted.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }
}
