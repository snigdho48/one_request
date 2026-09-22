import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_types.dart';

class PlusConnectivitySource implements ConnectivitySource {
  PlusConnectivitySource([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<List<NetworkKind>> check() async {
    final results = await _connectivity.checkConnectivity();
    return results.map(mapConnectivityResult).toList();
  }

  @override
  Stream<List<NetworkKind>> get onChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.map(mapConnectivityResult).toList(),
      );
}

NetworkKind mapConnectivityResult(ConnectivityResult result) {
  switch (result) {
    case ConnectivityResult.none:
      return NetworkKind.none;
    case ConnectivityResult.wifi:
      return NetworkKind.wifi;
    case ConnectivityResult.mobile:
      return NetworkKind.mobile;
    case ConnectivityResult.ethernet:
      return NetworkKind.ethernet;
    case ConnectivityResult.vpn:
      return NetworkKind.vpn;
    case ConnectivityResult.bluetooth:
      return NetworkKind.bluetooth;
    case ConnectivityResult.satellite:
      return NetworkKind.satellite;
    case ConnectivityResult.other:
      return NetworkKind.other;
  }
}
