import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'socket_connector.dart';
import 'socket_transport.dart';
import 'socket_uri.dart';

export 'socket_transport.dart';
export 'socket_uri.dart';

/// Lifecycle of an [OneSocket] connection.
enum SocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  closing,
}

/// Optional WebSocket client. Nothing connects until [OneSocket.connect] or
/// [OneRequest.socket] is called. Turn the feature off with
/// `OneRequest.configure(enableWebSocket: false)`.
class OneSocket {
  OneSocket._({
    required this.url,
    required this.uri,
    required Map<String, String> headers,
    required this.protocols,
    required this.pingInterval,
    required this.connectTimeout,
    required this.autoReconnect,
    required this.maxReconnectAttempts,
    required this.reconnectDelay,
    required this.encodeJson,
    required this.decodeJson,
    required SocketTransportFactory transportFactory,
    this.onMessage,
    this.onState,
    this.onError,
  })  : _headers = headers,
        _transportFactory = transportFactory;

  /// Kill switch. Default **on** so calling [connect] needs no extra setup.
  static bool _enabled = true;
  static bool _defaultAutoReconnect = false;
  static bool _defaultEncodeJson = true;
  static bool _defaultDecodeJson = true;
  static int _defaultMaxReconnectAttempts = 5;
  static Duration _defaultReconnectDelay = const Duration(seconds: 2);

  /// Tests replace the real `web_socket_channel` connection.
  @visibleForTesting
  static SocketTransportFactory? debugTransportFactory;

  static bool get isEnabled => _enabled;
  static bool get defaultAutoReconnect => _defaultAutoReconnect;
  static bool get defaultEncodeJson => _defaultEncodeJson;
  static bool get defaultDecodeJson => _defaultDecodeJson;
  static int get defaultMaxReconnectAttempts => _defaultMaxReconnectAttempts;
  static Duration get defaultReconnectDelay => _defaultReconnectDelay;

  static void setEnabled(bool enabled) => _enabled = enabled;

  static void configureDefaults({
    bool? autoReconnect,
    bool? encodeJson,
    bool? decodeJson,
    int? maxReconnectAttempts,
    Duration? reconnectDelay,
  }) {
    if (autoReconnect != null) {
      _defaultAutoReconnect = autoReconnect;
    }
    if (encodeJson != null) {
      _defaultEncodeJson = encodeJson;
    }
    if (decodeJson != null) {
      _defaultDecodeJson = decodeJson;
    }
    if (maxReconnectAttempts != null && maxReconnectAttempts >= 0) {
      _defaultMaxReconnectAttempts = maxReconnectAttempts;
    }
    if (reconnectDelay != null) {
      _defaultReconnectDelay = reconnectDelay;
    }
  }

  static void resetConfig() {
    _enabled = true;
    _defaultAutoReconnect = false;
    _defaultEncodeJson = true;
    _defaultDecodeJson = true;
    _defaultMaxReconnectAttempts = 5;
    _defaultReconnectDelay = const Duration(seconds: 2);
    debugTransportFactory = null;
  }

  final String url;
  final Uri uri;
  final Map<String, String> _headers;
  final Iterable<String>? protocols;
  final Duration? pingInterval;
  final Duration? connectTimeout;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final Duration reconnectDelay;
  final bool encodeJson;
  final bool decodeJson;
  final SocketTransportFactory _transportFactory;
  final void Function(dynamic message)? onMessage;
  final void Function(SocketState state)? onState;
  final void Function(Object error, StackTrace stackTrace)? onError;

  final StreamController<dynamic> _messages =
      StreamController<dynamic>.broadcast();
  final StreamController<SocketState> _states =
      StreamController<SocketState>.broadcast();
  final List<dynamic> _pending = <dynamic>[];

  SocketTransport? _transport;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  final Completer<void> _ready = Completer<void>();
  SocketState _state = SocketState.disconnected;
  bool _manualClose = false;
  int _reconnectAttempts = 0;

  Stream<dynamic> get messages => _messages.stream;
  Stream<SocketState> get states => _states.stream;
  SocketState get state => _state;
  Future<void> get ready => _ready.future;
  Map<String, String> get headers => Map<String, String>.unmodifiable(_headers);

  static OneSocket connect({
    required String url,
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, String>? globalHeaders,
    Iterable<String>? protocols,
    Duration? pingInterval,
    Duration? connectTimeout,
    bool? autoReconnect,
    int? maxReconnectAttempts,
    Duration? reconnectDelay,
    bool? encodeJson,
    bool? decodeJson,
    void Function(dynamic message)? onMessage,
    void Function(SocketState state)? onState,
    void Function(Object error, StackTrace stackTrace)? onError,
    SocketTransportFactory? transportFactory,
  }) {
    if (!_enabled) {
      throw StateError(
        'WebSocket is disabled. OneRequest.configure(enableWebSocket: true) '
        'turns it back on.',
      );
    }
    final merged = <String, String>{
      if (globalHeaders != null) ...globalHeaders,
      if (headers != null) ...headers,
    };
    final socket = OneSocket._(
      url: url,
      uri: resolveSocketUri(url, baseUrl: baseUrl),
      headers: merged,
      protocols: protocols,
      pingInterval: pingInterval,
      connectTimeout: connectTimeout,
      autoReconnect: autoReconnect ?? _defaultAutoReconnect,
      maxReconnectAttempts:
          maxReconnectAttempts ?? _defaultMaxReconnectAttempts,
      reconnectDelay: reconnectDelay ?? _defaultReconnectDelay,
      encodeJson: encodeJson ?? _defaultEncodeJson,
      decodeJson: decodeJson ?? _defaultDecodeJson,
      transportFactory:
          transportFactory ?? debugTransportFactory ?? openSocketTransport,
      onMessage: onMessage,
      onState: onState,
      onError: onError,
    );
    socket._open();
    return socket;
  }

  void send(dynamic data) {
    if (_manualClose) {
      throw StateError('WebSocket is closed.');
    }
    final payload = _encode(data);
    final transport = _transport;
    if (_state == SocketState.connected && transport != null) {
      transport.add(payload);
      return;
    }
    _pending.add(payload);
  }

  Future<void> close([int? code, String? reason]) async {
    _manualClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pending.clear();
    _setState(SocketState.closing);
    await _subscription?.cancel();
    _subscription = null;
    await _transport?.close(code, reason);
    _transport = null;
    _setState(SocketState.disconnected);
    if (!_messages.isClosed) {
      await _messages.close();
    }
    if (!_states.isClosed) {
      await _states.close();
    }
  }

  Future<void> _open() async {
    if (_manualClose) return;
    _setState(_reconnectAttempts == 0
        ? SocketState.connecting
        : SocketState.reconnecting);
    try {
      final transport = await _transportFactory(
        uri,
        protocols: protocols,
        headers: _headers.isEmpty ? null : _headers,
        pingInterval: pingInterval,
        connectTimeout: connectTimeout,
      );
      if (_manualClose) {
        await transport.close();
        return;
      }
      _transport = transport;
      await transport.ready;
      if (_manualClose) {
        await transport.close();
        return;
      }
      _listen(transport);
      _setState(SocketState.connected);
      _reconnectAttempts = 0;
      if (!_ready.isCompleted) {
        _ready.complete();
      }
      _flushPending();
    } catch (error, stack) {
      onError?.call(error, stack);
      if (!_ready.isCompleted && !autoReconnect) {
        _ready.completeError(error, stack);
      }
      _setState(SocketState.disconnected);
      _scheduleReconnect();
    }
  }

  void _listen(SocketTransport transport) {
    _subscription?.cancel();
    _subscription = transport.stream.listen(
      (event) {
        final decoded = _decode(event);
        if (!_messages.isClosed) {
          _messages.add(decoded);
        }
        onMessage?.call(decoded);
      },
      onError: (Object error, StackTrace stack) {
        onError?.call(error, stack);
        if (!_messages.isClosed) {
          _messages.addError(error, stack);
        }
        _scheduleReconnect();
      },
      onDone: () {
        if (_manualClose) {
          _setState(SocketState.disconnected);
          return;
        }
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _flushPending() {
    final transport = _transport;
    if (transport == null || _state != SocketState.connected) return;
    final queued = List<dynamic>.from(_pending);
    _pending.clear();
    for (final payload in queued) {
      transport.add(payload);
    }
  }

  void _scheduleReconnect() {
    if (_manualClose || !autoReconnect || !_enabled) {
      _setState(SocketState.disconnected);
      _failReadyIfNeeded();
      return;
    }
    if (maxReconnectAttempts > 0 &&
        _reconnectAttempts >= maxReconnectAttempts) {
      _setState(SocketState.disconnected);
      _failReadyIfNeeded();
      return;
    }
    _reconnectAttempts++;
    _setState(SocketState.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      unawaited(_open());
    });
  }

  void _failReadyIfNeeded() {
    if (!_ready.isCompleted) {
      _ready.completeError(
        StateError('WebSocket failed to connect: $uri'),
      );
    }
  }

  void _setState(SocketState next) {
    if (_state == next) return;
    _state = next;
    if (!_states.isClosed) {
      _states.add(next);
    }
    onState?.call(next);
  }

  dynamic _encode(dynamic data) {
    if (!encodeJson) return data;
    if (data is Map || data is List) {
      return jsonEncode(data);
    }
    return data;
  }

  dynamic _decode(dynamic data) {
    if (!decodeJson || data is! String) return data;
    final text = data.trim();
    if (text.isEmpty) return data;
    final first = text.codeUnitAt(0);
    if (first != 123 && first != 91) return data; // { or [
    try {
      return jsonDecode(text);
    } catch (_) {
      return data;
    }
  }
}
