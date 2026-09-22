import 'dart:async';

import 'package:flutter/foundation.dart';

import 'connectivity_types.dart';
import 'plus_source.dart';

export 'connectivity_types.dart';

/// Optional connectivity watcher. Off until [configure] / [OneRequest.setConnectivity].
class ConnectivityWatch extends ChangeNotifier {
  ConnectivityWatch._();

  static final ConnectivityWatch instance = ConnectivityWatch._();

  @visibleForTesting
  static ConnectivitySource? debugSource;

  static bool _enabled = false;
  static ConnectivityUi _ui = ConnectivityUi.snackbar;
  static bool _showOffline = true;
  static bool _showOnline = true;
  static String _offlineMessage = 'No internet connection';
  static String _onlineMessage = 'Back online';
  static Duration _noticeDuration = const Duration(seconds: 4);
  static ConnectivityBuilder? _builder;
  static ConnectivityChanged? _onChanged;

  StreamSubscription<List<NetworkKind>>? _subscription;
  ConnectivitySource? _liveSource;
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  ConnectivityEvent? _lastEvent;
  int _eventId = 0;
  final StreamController<ConnectivityStatus> _stream =
      StreamController<ConnectivityStatus>.broadcast();

  static bool get isEnabled => _enabled;
  static ConnectivityUi get ui => _ui;
  static bool get showOffline => _showOffline;
  static bool get showOnline => _showOnline;
  static String get offlineMessage => _offlineMessage;
  static String get onlineMessage => _onlineMessage;
  static Duration get noticeDuration => _noticeDuration;
  static ConnectivityBuilder? get builder => _builder;

  ConnectivityStatus get status => _status;
  ConnectivityEvent? get lastEvent => _lastEvent;
  Stream<ConnectivityStatus> get statuses => _stream.stream;

  static void configure({
    bool? enabled,
    ConnectivityUi? ui,
    bool? showOffline,
    bool? showOnline,
    String? offlineMessage,
    String? onlineMessage,
    Duration? noticeDuration,
    ConnectivityBuilder? builder,
    ConnectivityChanged? onChanged,
    bool clearBuilder = false,
    bool clearOnChanged = false,
  }) {
    if (enabled != null) {
      _enabled = enabled;
    }
    if (ui != null) {
      _ui = ui;
    }
    if (showOffline != null) {
      _showOffline = showOffline;
    }
    if (showOnline != null) {
      _showOnline = showOnline;
    }
    if (offlineMessage != null) {
      _offlineMessage = offlineMessage;
    }
    if (onlineMessage != null) {
      _onlineMessage = onlineMessage;
    }
    if (noticeDuration != null) {
      _noticeDuration = noticeDuration;
    }
    if (clearBuilder) {
      _builder = null;
    } else if (builder != null) {
      _builder = builder;
    }
    if (clearOnChanged) {
      _onChanged = null;
    } else if (onChanged != null) {
      _onChanged = onChanged;
    }
    if (_enabled) {
      unawaited(instance.start());
    } else {
      instance.stop();
    }
    instance.notifyListeners();
  }

  static void disable() {
    configure(
      enabled: false,
      clearBuilder: true,
      clearOnChanged: true,
    );
  }

  static void resetConfig() {
    instance.stop();
    _enabled = false;
    _ui = ConnectivityUi.snackbar;
    _showOffline = true;
    _showOnline = true;
    _offlineMessage = 'No internet connection';
    _onlineMessage = 'Back online';
    _noticeDuration = const Duration(seconds: 4);
    _builder = null;
    _onChanged = null;
    debugSource = null;
    instance._status = ConnectivityStatus.unknown;
    instance._lastEvent = null;
    instance._eventId = 0;
    instance.notifyListeners();
  }

  Future<ConnectivityStatus> checkOnce() async {
    final source = debugSource ?? _liveSource ?? PlusConnectivitySource();
    final kinds = await source.check();
    return ConnectivityStatus.fromKinds(kinds);
  }

  Future<void> start() async {
    if (_subscription != null) return;
    final source = debugSource ?? (_liveSource ??= PlusConnectivitySource());
    _subscription = source.onChanged.listen(
      (kinds) => _apply(kinds, initial: false),
    );
    try {
      _apply(await source.check(), initial: true);
    } catch (_) {
      // Plugin missing in tests / desktop without implementation — stay unknown.
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    if (debugSource == null) {
      _liveSource = null;
    }
  }

  void _apply(List<NetworkKind> kinds, {required bool initial}) {
    final previous = _status;
    final next = ConnectivityStatus.fromKinds(kinds);
    _status = next;
    if (!_stream.isClosed) {
      _stream.add(next);
    }
    _onChanged?.call(next);
    final shouldEmit = _shouldEmitEvent(
      previous: previous,
      next: next,
      initial: initial,
    );
    if (shouldEmit) {
      _lastEvent = ConnectivityEvent(
        id: ++_eventId,
        online: next.online,
        initial: initial,
      );
    }
    notifyListeners();
  }

  bool _shouldEmitEvent({
    required ConnectivityStatus previous,
    required ConnectivityStatus next,
    required bool initial,
  }) {
    if (!_enabled || _ui == ConnectivityUi.none) return false;
    if (initial) {
      return !next.online && _showOffline;
    }
    if (previous.online && !next.online) {
      return _showOffline;
    }
    if (!previous.online && next.online) {
      return _showOnline;
    }
    return false;
  }
}
