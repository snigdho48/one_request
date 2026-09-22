import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_request/one_request.dart';

/// In-memory Dio adapter so send/request work on VM and Chrome without network.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.status, this.body);

  final int status;
  final String body;
  final List<Uri> uris = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    uris.add(options.uri);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpClientAdapter previousAdapter;

  setUp(() {
    previousAdapter = OneRequest.client.httpClientAdapter;
    OneRequest.resetConfig();
    OneRequest.resetErrorHandler();
    OneRequest.configure(
      enableLoader: false,
      enableErrorOverlay: false,
      enableSuccessOverlay: false,
    );
  });

  tearDown(() {
    OneRequest.client.httpClientAdapter = previousAdapter;
    OneRequest.resetConfig();
    OneRequest.clearAuth();
  });

  test('shared APIs compile on ${kIsWeb ? 'web' : 'vm'} (hasDartIo=$hasDartIo)',
      () {
    expect(hasDartIo, isNot(kIsWeb));
    expect(RequestType.GET.value, 'GET');
    expect(ResponseType.json, isNotNull);
    expect(RestErrorParser.messageFromBody({'error': 'x'}), 'x');
    expect(
      CustomExceptionHandlers(error: const FormatException('bad'))
          .getExceptionString(),
      'Invalid data format.',
    );
    expect(
      CustomExceptionHandlers(error: TimeoutException('t'))
          .getExceptionString(),
      'Request timedout.',
    );
    final bytes = OneRequest().fileFromByte(filebyte: const [1, 2, 3]);
    expect(bytes, isA<MultipartFile>());
    final text = OneRequest().fileFormString(filestring: 'hello');
    expect(text, isA<MultipartFile>());
  });

  test('path uploads are native-only', () async {
    if (hasDartIo) {
      expect(hasDartIo, isTrue);
      return;
    }
    await expectLater(
      OneRequest().fileFromPath(path: '/nope'),
      throwsA(isA<UnsupportedError>()),
    );
  });

  testWidgets('wrap() is optional and builds on this platform', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: OneRequest.wrap(),
      home: const SizedBox.shrink(),
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  }, skip: kIsWeb); // EasyLoading chrome compile is slow; covered on VM

  test('send/request succeed through a fake adapter on this platform',
      () async {
    OneRequest.client.httpClientAdapter = _JsonAdapter(200, '{"fact":"ok"}');
    final sent = await OneRequest().send<Map<String, dynamic>>(
      url: 'https://example.test/fact',
      method: RequestType.GET,
      loader: false,
      resultOverlay: false,
    );
    expect(sent.isRight, isTrue);
    expect(sent.getOrNull()?['fact'], 'ok');

    final data = await OneRequest().request<Map<String, dynamic>>(
      url: 'https://example.test/fact',
      method: RequestType.GET,
      loader: false,
      resultOverlay: false,
    );
    expect(data['fact'], 'ok');
  });

  test('absolute HTTP urls ignore configure baseUrl', () async {
    OneRequest.configure(baseUrl: 'https://api.example.com');
    final adapter = _JsonAdapter(200, '{"ok":true}');
    OneRequest.client.httpClientAdapter = adapter;
    await OneRequest().send<Map<String, dynamic>>(
      url: 'https://pay.example.com/charge',
      method: RequestType.GET,
      loader: false,
      resultOverlay: false,
    );
    expect(adapter.uris.single.toString(), 'https://pay.example.com/charge');
  });

  test('instance baseUrl is independent of configure baseUrl', () async {
    OneRequest.configure(baseUrl: 'https://api.example.com');
    final adapter = _JsonAdapter(200, '{"ok":true}');
    OneRequest.client.httpClientAdapter = adapter;
    final shop = OneRequest(baseUrl: 'https://shop.example.com');
    final catalog = OneRequest(baseUrl: 'https://catalog.example.com');
    await shop.send<Map<String, dynamic>>(
      url: '/orders',
      method: RequestType.GET,
      loader: false,
      resultOverlay: false,
    );
    await catalog.send<Map<String, dynamic>>(
      url: '/items',
      method: RequestType.GET,
      loader: false,
      resultOverlay: false,
    );
    expect(adapter.uris.map((u) => u.toString()).toList(), [
      'https://shop.example.com/orders',
      'https://catalog.example.com/items',
    ]);
  });

  test('send returns Left on HTTP error on this platform', () async {
    OneRequest.client.httpClientAdapter =
        _JsonAdapter(400, '{"error":"bad coupon"}');
    final sent = await OneRequest().send<Map<String, dynamic>>(
      url: 'https://example.test/fail',
      method: RequestType.GET,
      loader: false,
      resultOverlay: false,
    );
    expect(sent.isLeft, isTrue);
    expect(sent.leftOrNull(), contains('bad coupon'));
  });
}
