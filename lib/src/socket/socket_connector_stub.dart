import 'package:web_socket_channel/web_socket_channel.dart';

import 'socket_transport.dart';

/// Web / WASM: browsers cannot set extra WebSocket headers.
Future<SocketTransport> openSocketTransport(
  Uri uri, {
  Iterable<String>? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
  Duration? connectTimeout,
}) async {
  final channel = WebSocketChannel.connect(
    uri,
    protocols: protocols,
  );
  return ChannelSocketTransport(channel);
}
