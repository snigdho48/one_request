import 'package:flutter/widgets.dart';

/// Network transport reported by the connectivity watcher.
enum NetworkKind {
  none,
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  satellite,
  other,
}

/// Snapshot of whether any non-[NetworkKind.none] interface is up.
class ConnectivityStatus {
  const ConnectivityStatus({
    required this.online,
    required this.connections,
  });

  factory ConnectivityStatus.fromKinds(Iterable<NetworkKind> kinds) {
    final list = List<NetworkKind>.unmodifiable(kinds);
    final online = list.any((kind) => kind != NetworkKind.none);
    return ConnectivityStatus(online: online, connections: list);
  }

  /// Used before the first plugin reading. Treated as online so startup is silent.
  static const unknown = ConnectivityStatus(
    online: true,
    connections: <NetworkKind>[],
  );

  /// True when at least one connection is not [NetworkKind.none].
  final bool online;

  /// Active interface kinds from the last plugin event.
  final List<NetworkKind> connections;

  @override
  bool operator ==(Object other) {
    return other is ConnectivityStatus &&
        other.online == online &&
        _sameKinds(other.connections, connections);
  }

  @override
  int get hashCode => Object.hash(online, Object.hashAll(connections));
}

bool _sameKinds(List<NetworkKind> a, List<NetworkKind> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Default notice style when connectivity is enabled. [none] still watches.
enum ConnectivityUi {
  /// Watch only — no package UI.
  none,

  /// Floating bar while offline; brief bar when back online.
  snackbar,

  /// Persistent top bar while offline.
  banner,

  /// Dismissible top card while offline.
  popover,
}

/// Full-tree replacement for the default connectivity overlay.
typedef ConnectivityBuilder = Widget Function(
  BuildContext context,
  ConnectivityStatus status,
  Widget child,
);

/// Fired on every connectivity snapshot (including the first check).
typedef ConnectivityChanged = void Function(ConnectivityStatus status);

/// Injectable connectivity source (or a fake in tests).
abstract class ConnectivitySource {
  Future<List<NetworkKind>> check();
  Stream<List<NetworkKind>> get onChanged;
}

/// UI-facing transition emitted when a notice should appear.
class ConnectivityEvent {
  ConnectivityEvent({
    required this.id,
    required this.online,
    required this.initial,
  });

  final int id;
  final bool online;
  final bool initial;
}
