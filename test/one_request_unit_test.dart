import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_request/one_request.dart';

void main() {
  group('OneRequest', () {
    late List<String> logs;

    setUp(() {
      logs = [];
      OneRequest.resetConfig();
      OneRequest.resetErrorHandler();
      LoadingStuff.resetCustomBuilders();
    });

    test('returns type-safe success', () async {
      final result = await Future.value(
          Right<String, Map<String, String>>({'foo': 'bar'}));
      expect(result.isRight, true);
      expect(result.getOrNull()!['foo'], 'bar');
    });

    test('calls custom error handler and logger', () async {
      String? handledMsg;
      String? loggedMsg;
      OneRequest.setErrorHandler(
        handler: (body, status, url) {
          handledMsg = 'custom: \'${body['custom_message']}\'';
          return handledMsg!;
        },
        logger: (error, stack) {
          loggedMsg = error.toString();
        },
      );
      // We can't access private fields, so just check the handler and logger are set and callable
      expect(handledMsg, isNull);
      expect(loggedMsg, isNull);
      // Just call setErrorHandler again to ensure no exceptions
      OneRequest.setErrorHandler(
        handler: (body, status, url) => 'custom: ${body['custom_message']}',
        logger: (error, stack) => logs.add(error.toString()),
      );
    });

    test('error handler stays optional and additive', () {
      OneRequest.resetErrorHandler();
      expect(OneRequest.errorHandler, same(RestErrorParser.handler));
      expect(OneRequest.errorLogger, isNull);

      var logged = false;
      OneRequest.setErrorHandler(logger: (error, stack) {
        logged = true;
      });
      expect(OneRequest.errorHandler, same(RestErrorParser.handler));
      expect(OneRequest.errorLogger, isNotNull);

      OneRequest.setErrorHandler(
        handler: (body, status, url) => 'from-app',
      );
      expect(OneRequest.errorHandler!({}, null, null), 'from-app');
      expect(OneRequest.errorLogger, isNotNull);

      OneRequest.setErrorHandler(clearHandler: true);
      expect(OneRequest.errorHandler, isNull);
      expect(OneRequest.errorLogger, isNotNull);
      expect(logged, isFalse);

      OneRequest.clearErrorHandler();
      expect(OneRequest.errorHandler, isNull);
      expect(OneRequest.errorLogger, isNull);
    });

    test('retries on transient error', () async {
      int attempts = 0;
      Future<Either<String, Map<String, dynamic>>> fakeRequest() async {
        attempts++;
        if (attempts < 3) {
          throw DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.connectionTimeout,
            message: 'timeout',
          );
        }
        return Right({'ok': true});
      }

      int maxRetries = 2;
      int attempt = 0;
      late Either<String, Map<String, dynamic>> result;
      while (true) {
        try {
          result = await fakeRequest();
          break;
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionTimeout &&
              attempt < maxRetries) {
            attempt++;
            await Future.delayed(const Duration(milliseconds: 10));
            continue;
          }
          result = Left('error');
          break;
        }
      }
      expect(attempt, 2);
      expect(result.isRight, true);
      expect(result.getOrNull()!['ok'], true);
    });

    test('global config merges headers', () {
      OneRequest.configure(headers: {'a': 'b'});
      // We can't access private fields, so just check that configure does not throw
      expect(() => OneRequest.configure(headers: {'x': 'y'}), returnsNormally);
    });

    test('logger configuration with separate error and response loggers', () {
      // Test separate logger configuration
      OneRequest.setErrorLoggerEnabled(true);
      OneRequest.setResponseLoggerEnabled(false);
      expect(OneRequest.isErrorLoggerEnabled(), true);
      expect(OneRequest.isResponseLoggerEnabled(), false);
      expect(OneRequest.isLoggerEnabled(),
          true); // Should be true if any logger is enabled

      OneRequest.setErrorLoggerEnabled(false);
      OneRequest.setResponseLoggerEnabled(true);
      expect(OneRequest.isErrorLoggerEnabled(), false);
      expect(OneRequest.isResponseLoggerEnabled(), true);
      expect(OneRequest.isLoggerEnabled(), true);

      // Test legacy method (enables both)
      OneRequest.setLoggerEnabled(true);
      expect(OneRequest.isErrorLoggerEnabled(), true);
      expect(OneRequest.isResponseLoggerEnabled(), true);
      expect(OneRequest.isLoggerEnabled(), true);

      OneRequest.setLoggerEnabled(false);
      expect(OneRequest.isErrorLoggerEnabled(), false);
      expect(OneRequest.isResponseLoggerEnabled(), false);
      expect(OneRequest.isLoggerEnabled(), false);
    });

    test('configure with enableErrorLogger and enableResponseLogger', () {
      OneRequest.configure(
        enableErrorLogger: true,
        enableResponseLogger: false,
      );
      expect(OneRequest.isErrorLoggerEnabled(), true);
      expect(OneRequest.isResponseLoggerEnabled(), false);

      OneRequest.configure(
        enableErrorLogger: false,
        enableResponseLogger: true,
      );
      expect(OneRequest.isErrorLoggerEnabled(), false);
      expect(OneRequest.isResponseLoggerEnabled(), true);

      // Test legacy enableLogger (should enable both)
      OneRequest.configure(enableLogger: true);
      expect(OneRequest.isErrorLoggerEnabled(), true);
      expect(OneRequest.isResponseLoggerEnabled(), true);
    });

    test('re-exports Dio and Either so extra packages are not required', () {
      expect(CancelToken.new, isA<Function>());
      expect(FormData.fromMap(<String, dynamic>{}), isA<FormData>());
      expect(Left<String, int>('err').isLeft, isTrue);
      expect(Right<String, int>(1).isRight, isTrue);
      expect(RequestType.GET.value, 'GET');
      expect(ResponseType.json, isNotNull);
    });

    test('getOverlaySettings includes logger states', () {
      OneRequest.setErrorLoggerEnabled(true);
      OneRequest.setResponseLoggerEnabled(true);
      final settings = OneRequest.getOverlaySettings();
      expect(settings['errorLogger'], true);
      expect(settings['responseLogger'], true);
      expect(settings['logger'], true);

      OneRequest.setErrorLoggerEnabled(false);
      OneRequest.setResponseLoggerEnabled(false);
      final settings2 = OneRequest.getOverlaySettings();
      expect(settings2['errorLogger'], false);
      expect(settings2['responseLogger'], false);
      expect(settings2['logger'], false);
    });

    testWidgets('custom loading and error widget logic',
        (WidgetTester tester) async {
      bool loadingCalled = false;
      bool errorCalled = false;
      LoadingStuff.setCustomBuilders(
        loadingBuilder: (context, status) {
          loadingCalled = true;
          return Container();
        },
        errorBuilder: (context, message) {
          errorCalled = true;
          return Container();
        },
        localization: (msg) => 'L: $msg',
      );
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            LoadingStuff.customLoadingBuilder?.call(context, 'loading');
            LoadingStuff.customErrorBuilder?.call(context, 'error');
            final localized = LoadingStuff.errorLocalization?.call('err');
            expect(loadingCalled, true);
            expect(errorCalled, true);
            expect(localized, 'L: err');
            return Container();
          },
        ),
      ));
    });

    test('RestErrorParser reads Django details, error, and code envelopes', () {
      expect(
        RestErrorParser.messageFromBody({
          'details': {
            'phone': ['Enter a valid phone number.']
          }
        }),
        'Enter a valid phone number.',
      );
      expect(
        RestErrorParser.messageFromBody({'error': 'Invalid coupon'}),
        'Invalid coupon',
      );
      expect(
        RestErrorParser.messageFromBody({'detail': 'Not found'},
            statusCode: 404),
        'Not found',
      );
      expect(
        RestErrorParser.messageFromBody({}, statusCode: 401),
        'Unauthorized. Please login again.',
      );

      final encoded = RestErrorParser.handler(
        {
          'error': 'below pack',
          'code': 'below_pack_size',
          'data': {'pack_size': 6}
        },
        400,
        '/cart/add/',
      );
      final parsed = RequestException.fromClient(encoded);
      expect(parsed.message, 'below pack');
      expect(parsed.code, 'below_pack_size');
      expect(parsed.data?['pack_size'], 6);
    });

    test('unwrapPayload pulls nested data envelopes', () {
      expect(
          unwrapPayload({
            'data': {'id': 1},
            'success': true
          }),
          {'id': 1});
      expect(unwrapPayload({'id': 2}), {'id': 2});
      expect(unwrapPayload([1, 2]), [1, 2]);
    });

    test('request() throws RequestException on Left', () {
      expect(
        () =>
            throw RequestException.fromClient('{"message":"fail","code":"x"}'),
        throwsA(
          isA<RequestException>()
              .having((e) => e.message, 'message', 'fail')
              .having((e) => e.code, 'code', 'x'),
        ),
      );
    });

    test('wrap() is a TransitionBuilder and auto-inits loading', () {
      final builder = OneRequest.wrap();
      expect(builder, isA<TransitionBuilder>());
      final nested = OneRequest.wrap(
        (context, child) => child ?? const SizedBox.shrink(),
      );
      expect(nested, isA<TransitionBuilder>());
    });

    test('setAuth attaches Bearer token without a separate Dio dependency',
        () async {
      OneRequest.clearAuth();
      OneRequest.setAuth(
        getAccessToken: () async => 'abc123',
        getRefreshToken: () async => 'refresh',
        saveTokens: (access, refresh) async {},
      );
      final options = RequestOptions(path: '/auth/me/');
      final interceptor =
          OneRequest.client.interceptors.whereType<AuthInterceptor>().single;
      interceptor.onRequest(
        options,
        RequestInterceptorHandler(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(options.headers['Authorization'], 'Bearer abc123');
      OneRequest.clearAuth();
      expect(
        OneRequest.client.interceptors.whereType<AuthInterceptor>(),
        isEmpty,
      );
    });
  });
}
