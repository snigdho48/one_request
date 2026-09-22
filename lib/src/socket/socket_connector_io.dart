import 'package:web_socket_channel/io.dart';

import 'socket_transport.dart';

Future<SocketTransport> openSocketTransport(
  Uri uri, {
  Iterable<String>? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
  Duration? connectTimeout,
}) async {
  final channel = IOWebSocketChannel.connect(
    uri,
    protocols: protocols,
    headers: headers,
    pingInterval: pingInterval,
    connectTimeout: connectTimeout,
  );
  return ChannelSocketTransport(channel);
}
