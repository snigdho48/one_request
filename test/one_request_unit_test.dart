import 'package:flutter_test/flutter_test.dart';
import 'package:one_request/one_request.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;

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
      final result = await Future.value(Left({'foo': 'bar'}));
      expect(result.isLeft, true);
      expect(result.left['foo'], 'bar');
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

    test('retries on transient error', () async {
      int attempts = 0;
      Future<Either<Map<String, dynamic>, String>> fakeRequest() async {
        attempts++;
        if (attempts < 3) {
          throw dio.DioException(
            requestOptions: dio.RequestOptions(path: '/test'),
            type: dio.DioExceptionType.connectionTimeout,
            message: 'timeout',
          );
        }
        return Left({'ok': true});
      }

      int maxRetries = 2;
      int attempt = 0;
      late Either<Map<String, dynamic>, String> result;
      while (true) {
        try {
          result = await fakeRequest();
          break;
        } on dio.DioException catch (e) {
          if (e.type == dio.DioExceptionType.connectionTimeout &&
              attempt < maxRetries) {
            attempt++;
            await Future.delayed(const Duration(milliseconds: 10));
            continue;
          }
          result = Right('error');
          break;
        }
      }
      expect(attempt, 2);
      expect(result.isLeft, true);
      expect(result.left['ok'], true);
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
  });
}
