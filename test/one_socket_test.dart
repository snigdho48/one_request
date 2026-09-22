import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:one_request/one_request.dart';

class _FakeTransport implements SocketTransport {
  _FakeTransport();

  final StreamController<dynamic> incoming =
      StreamController<dynamic>.broadcast();
  final List<dynamic> sent = <dynamic>[];
  Completer<void> readyCompleter = Completer<void>()..complete();
  bool closed = false;
  int? closeCode;
  String? closeReason;

  @override
  Future<void> get ready => readyCompleter.future;

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  void add(dynamic data) => sent.add(data);

  @override
  Future<void> close([int? code, String? reason]) async {
    closed = true;
    closeCode = code;
    closeReason = reason;
    if (!incoming.isClosed) {
      await incoming.close();
    }
  }

  void emit(dynamic data) => incoming.add(data);

  void fail(Object error, [StackTrace? stack]) =>
      incoming.addError(error, stack);
}

void main() {
  late List<_FakeTransport> transports;

  setUp(() {
    transports = <_FakeTransport>[];
    OneRequest.resetConfig();
    OneSocket.debugTransportFactory =
        (uri, {protocols, headers, pingInterval, connectTimeout}) async {
      final transport = _FakeTransport();
      transports.add(transport);
      return transport;
    };
  });

  tearDown(() async {
    OneSocket.debugTransportFactory = null;
    OneRequest.resetConfig();
  });

  test('resolveSocketUri converts http(s) and joins relative paths', () {
    expect(
      resolveSocketUri('wss://chat.example/ws').toString(),
      'wss://chat.example/ws',
    );
    expect(
      resolveSocketUri('https://api.example.com/ws').toString(),
      'wss://api.example.com/ws',
    );
    expect(
      resolveSocketUri('http://api.example.com/ws').toString(),
      'ws://api.example.com/ws',
    );
    expect(
      resolveSocketUri('/ws/chat', baseUrl: 'https://api.example.com')
          .toString(),
      'wss://api.example.com/ws/chat',
    );
    expect(
      resolveSocketUri('wss://other.example/ws',
              baseUrl: 'https://api.example.com')
          .toString(),
      'wss://other.example/ws',
    );
  });

  test('resolveRequestUrl never prefixes an absolute host', () {
    expect(
      resolveRequestUrl('/users', baseUrl: 'https://api.example.com'),
      'https://api.example.com/users',
    );
    expect(
      resolveRequestUrl('https://pay.example.com/charge',
          baseUrl: 'https://api.example.com'),
      'https://pay.example.com/charge',
    );
    expect(
      resolveRequestUrl('wss://live.example.com/ws',
          baseUrl: 'https://api.example.com'),
      'wss://live.example.com/ws',
    );
    expect(resolveRequestUrl('/users'), '/users');
  });

  test('each socket() call is its own instance and host', () async {
    OneRequest.configure(baseUrl: 'https://api.example.com');
    final chat = OneRequest.socket(url: '/ws/chat');
    final live = OneRequest.socket(url: 'wss://live.example.com/feed');
    final pay = OneRequest.socket(
      url: '/ws',
      baseUrl: 'https://pay.example.com',
    );
    await Future.wait([chat.ready, live.ready, pay.ready]);

    expect(chat.uri.toString(), 'wss://api.example.com/ws/chat');
    expect(live.uri.toString(), 'wss://live.example.com/feed');
    expect(pay.uri.toString(), 'wss://pay.example.com/ws');
    expect(identical(chat, live), isFalse);

    await chat.close();
    await live.close();
    await pay.close();
  });

  test('instance openSocket uses that client baseUrl', () async {
    OneRequest.configure(baseUrl: 'https://api.example.com');
    final realtime = OneRequest(baseUrl: 'https://realtime.example.com');
    final socket = realtime.openSocket(url: '/ws/feed');
    await socket.ready;
    expect(socket.uri.toString(), 'wss://realtime.example.com/ws/feed');
    await socket.close();
  });

  test('socket send encodes JSON maps and passes strings through', () async {
    final socket = OneRequest.socket(url: 'wss://example.test/ws');
    await socket.ready;
    socket.send({'type': 'hello'});
    socket.send('plain');
    expect(transports, hasLength(1));
    expect(transports.first.sent, ['{"type":"hello"}', 'plain']);
    await socket.close();
  });

  test('incoming JSON strings are decoded unless decodeJson is false',
      () async {
    final decoded = OneRequest.socket(url: 'wss://example.test/ws');
    await decoded.ready;
    final raw =
        OneRequest.socket(url: 'wss://example.test/ws', decodeJson: false);
    await raw.ready;

    final decodedEvents = <dynamic>[];
    final rawEvents = <dynamic>[];
    decoded.messages.listen(decodedEvents.add);
    raw.messages.listen(rawEvents.add);

    transports[0].emit('{"ok":true}');
    transports[1].emit('{"ok":true}');
    await Future<void>.delayed(Duration.zero);

    expect(decodedEvents.single, {'ok': true});
    expect(rawEvents.single, '{"ok":true}');

    await decoded.close();
    await raw.close();
  });

  test('disabled websocket refuses to connect', () {
    OneRequest.configure(enableWebSocket: false);
    expect(OneRequest.isWebSocketEnabled(), isFalse);
    expect(
      () => OneRequest.socket(url: 'wss://example.test/ws'),
      throwsA(isA<StateError>()),
    );
  });

  test('close is manual and does not reconnect', () async {
    final socket = OneRequest.socket(
      url: 'wss://example.test/ws',
      autoReconnect: true,
    );
    await socket.ready;
    expect(socket.state, SocketState.connected);
    await socket.close(1000, 'bye');
    expect(socket.state, SocketState.disconnected);
    expect(transports, hasLength(1));
    expect(transports.first.closed, isTrue);
    expect(transports.first.closeCode, 1000);
    expect(transports.first.closeReason, 'bye');
  });

  test('autoReconnect opens a new transport after drop', () async {
    final socket = OneRequest.socket(
      url: 'wss://example.test/ws',
      autoReconnect: true,
      reconnectDelay: Duration.zero,
      maxReconnectAttempts: 3,
    );
    await socket.ready;
    expect(transports, hasLength(1));

    await transports.first.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(transports, hasLength(2));
    expect(socket.state, SocketState.connected);
    await socket.close();
  });

  test('per-socket headers merge over global headers', () async {
    Map<String, dynamic>? seenHeaders;
    OneSocket.debugTransportFactory =
        (uri, {protocols, headers, pingInterval, connectTimeout}) async {
      seenHeaders = headers;
      final transport = _FakeTransport();
      transports.add(transport);
      return transport;
    };

    OneRequest.configure(headers: {'X-App': 'one', 'Accept': 'json'});
    final socket = OneRequest.socket(
      url: 'wss://example.test/ws',
      headers: {'Accept': 'ws', 'X-Socket': '1'},
    );
    await socket.ready;
    expect(seenHeaders, {
      'X-App': 'one',
      'Accept': 'ws',
      'X-Socket': '1',
    });
    await socket.close();
  });

  test('configure omit leaves websocket knobs unchanged', () {
    OneRequest.configure(
      enableWebSocket: false,
      wsAutoReconnect: true,
      wsEncodeJson: false,
    );
    OneRequest.configure(baseUrl: 'https://api.example.com');
    expect(OneRequest.isWebSocketEnabled(), isFalse);
    expect(OneSocket.defaultAutoReconnect, isTrue);
    expect(OneSocket.defaultEncodeJson, isFalse);
  });
}
