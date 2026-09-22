import 'package:web_socket_channel/web_socket_channel.dart';

/// Byte/text pipe used by [OneSocket]. Tests inject a fake; production uses
/// [ChannelSocketTransport].
abstract class SocketTransport {
  /// Completes when the socket can send.
  Future<void> get ready;

  /// Incoming frames (String or bytes).
  Stream<dynamic> get stream;

  /// Send a frame.
  void add(dynamic data);

  /// Close the connection.
  Future<void> close([int? code, String? reason]);
}

/// Opens a [SocketTransport] for [uri]. Production default is platform connect.
typedef SocketTransportFactory = Future<SocketTransport> Function(
  Uri uri, {
  Iterable<String>? protocols,
  Map<String, dynamic>? headers,
  Duration? pingInterval,
  Duration? connectTimeout,
});

/// Default transport over `web_socket_channel`.
class ChannelSocketTransport implements SocketTransport {
  ChannelSocketTransport(this.channel);

  /// Underlying channel.
  final WebSocketChannel channel;

  @override
  Future<void> get ready => channel.ready;

  @override
  Stream<dynamic> get stream => channel.stream;

  @override
  void add(dynamic data) => channel.sink.add(data);

  @override
  Future<void> close([int? code, String? reason]) =>
      channel.sink.close(code, reason);
}
