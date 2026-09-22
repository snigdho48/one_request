/// one_request example: HTTP, optional WebSocket, optional connectivity UI.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_request/one_request.dart';

void main() {
  OneRequest.configure(
    enableErrorLogger: kDebugMode,
    enableResponseLogger: kDebugMode,
    enableLoader: true,
    enableErrorOverlay: false,
    enableSuccessOverlay: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: OneRequest.wrap(),
      title: 'one_request example',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const ExamplePage(),
    );
  }
}

enum _ConnPreset { off, snackbar, popover, banner, watchOnly, custom }

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _api = OneRequest(baseUrl: 'https://catfact.ninja');
  String _result = 'Tap a button.';
  bool _busy = false;
  _ConnPreset _conn = _ConnPreset.off;
  OneSocket? _socket;
  SocketState _socketState = SocketState.disconnected;
  StreamSubscription<SocketState>? _socketStates;
  StreamSubscription<dynamic>? _socketMessages;
  StreamSubscription<ConnectivityStatus>? _connSub;
  ConnectivityStatus _connStatus = ConnectivityStatus.unknown;

  @override
  void initState() {
    super.initState();
    _connSub = OneRequest.connectivity.listen((status) {
      if (mounted) setState(() => _connStatus = status);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    unawaited(_closeSocket());
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _getWithRequest() async {
    try {
      final data = await _api.request<Map<String, dynamic>>(
        url: '/fact',
        method: RequestType.GET,
      );
      setState(() => _result = 'request(): ${data['fact']}');
    } on RequestException catch (e) {
      setState(() => _result = 'RequestException: ${e.message}');
    }
  }

  Future<void> _getWithSend() async {
    final result = await _api.send<Map<String, dynamic>>(
      url: '/fact',
      method: RequestType.GET,
    );
    result.fold(
      ifRight: (data) => setState(() => _result = 'send(): ${data['fact']}'),
      ifLeft: (error) => setState(() => _result = 'Left: $error'),
    );
  }

  Future<void> _getCached() async {
    final result = await _api.send<Map<String, dynamic>>(
      url: '/fact',
      method: RequestType.GET,
      useCache: true,
    );
    result.fold(
      ifRight: (data) => setState(() => _result = 'cached: ${data['fact']}'),
      ifLeft: (error) => setState(() => _result = error),
    );
  }

  Future<void> _batch() async {
    final results = await OneRequest.batch<Map<String, dynamic>>([
      {'url': '/fact', 'method': RequestType.GET, 'useCache': true},
      {'url': '/fact', 'method': RequestType.GET},
    ]);
    setState(() {
      _result = results
          .asMap()
          .entries
          .map((e) => e.value.isRight
              ? 'Batch ${e.key + 1}: ${e.value.getOrNull()?['fact']}'
              : 'Batch ${e.key + 1}: ${e.value.leftOrNull()}')
          .join('\n');
    });
  }

  Future<void> _uploadBytes() async {
    final result = await _api.send<Map<String, dynamic>>(
      url: '/upload',
      method: RequestType.POST,
      formData: true,
      body: {
        'file': _api.fileFromByte(filebyte: const [1, 2, 3, 4]),
      },
    );
    result.fold(
      ifRight: (data) => setState(() => _result = data.toString()),
      ifLeft: (error) => setState(() => _result = error),
    );
  }

  void _applyConnectivity(_ConnPreset preset) {
    _conn = preset;
    switch (preset) {
      case _ConnPreset.off:
        OneRequest.clearConnectivity();
      case _ConnPreset.snackbar:
        OneRequest.setConnectivity(
          ui: ConnectivityUi.snackbar,
          clearBuilder: true,
          clearOnChanged: true,
        );
      case _ConnPreset.popover:
        OneRequest.setConnectivity(
          ui: ConnectivityUi.popover,
          clearBuilder: true,
          clearOnChanged: true,
        );
      case _ConnPreset.banner:
        OneRequest.setConnectivity(
          ui: ConnectivityUi.banner,
          clearBuilder: true,
          clearOnChanged: true,
        );
      case _ConnPreset.watchOnly:
        OneRequest.setConnectivity(
          ui: ConnectivityUi.none,
          clearBuilder: true,
          onChanged: (status) {
            if (mounted) setState(() => _connStatus = status);
          },
        );
      case _ConnPreset.custom:
        OneRequest.setConnectivity(
          builder: (context, status, child) {
            return Stack(
              children: [
                child,
                if (!status.online)
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Material(
                      color: Colors.black87,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'custom offline builder',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
    }
    setState(() => _result = 'Connectivity: ${preset.name}');
  }

  Future<void> _connectSocket() async {
    await _closeSocket();
    try {
      final socket = OneRequest.socket(
        url: 'wss://echo.websocket.events', // different host than HTTP base
        autoReconnect: false,
        onState: (state) {
          if (mounted) setState(() => _socketState = state);
        },
      );
      _socket = socket;
      _socketStates = socket.states.listen((state) {
        if (mounted) setState(() => _socketState = state);
      });
      _socketMessages = socket.messages.listen((event) {
        if (mounted) setState(() => _result = 'WS recv: $event');
      });
      await socket.ready;
      if (mounted) {
        setState(() {
          _socketState = socket.state;
          _result = 'WS connected ${socket.uri}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _result = 'WS error: $e');
    }
  }

  void _sendSocket() {
    final socket = _socket;
    if (socket == null) {
      setState(() => _result = 'Connect a socket first.');
      return;
    }
    socket
        .send({'hello': 'one_request', 't': DateTime.now().toIso8601String()});
    setState(() => _result = 'WS sent JSON hello');
  }

  Future<void> _closeSocket() async {
    await _socketStates?.cancel();
    await _socketMessages?.cancel();
    _socketStates = null;
    _socketMessages = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      await socket.close(1000, 'example');
    }
    if (mounted) {
      setState(() => _socketState = SocketState.disconnected);
    }
  }

  void _toggleWebSocketKillSwitch(bool enabled) {
    if (!enabled) {
      unawaited(_closeSocket());
    }
    OneRequest.configure(enableWebSocket: enabled);
    setState(() {
      _result = enabled
          ? 'WebSocket enabled (still idle until Connect).'
          : 'WebSocket hard-disabled. socket() will throw.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('one_request example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) const LinearProgressIndicator(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    'WS ${_socketState.name} · enabled=${OneRequest.isWebSocketEnabled()}',
                  ),
                ),
                Chip(
                  label: Text(
                    'net ${OneRequest.isConnectivityEnabled() ? (_connStatus.online ? 'online' : 'offline') : 'off'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const Text('HTTP'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _busy ? null : () => _run(_getWithRequest),
                  child: const Text('GET request()'),
                ),
                FilledButton.tonal(
                  onPressed: _busy ? null : () => _run(_getWithSend),
                  child: const Text('GET send()'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(_getCached),
                  child: const Text('GET + cache'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(_batch),
                  child: const Text('Batch'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(_uploadBytes),
                  child: const Text('Upload bytes'),
                ),
                TextButton(
                  onPressed: () {
                    OneRequest.clearCache();
                    setState(() => _result = 'Cache cleared.');
                  },
                  child: const Text('Clear cache'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Connectivity (off until you pick a UI)'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _ConnPreset.values)
                  ChoiceChip(
                    label: Text(preset.name),
                    selected: _conn == preset,
                    onSelected: (_) => _applyConnectivity(preset),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('WebSocket'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _busy ? null : () => _run(_connectSocket),
                  child: const Text('Connect echo'),
                ),
                OutlinedButton(
                  onPressed: _sendSocket,
                  child: const Text('Send JSON'),
                ),
                OutlinedButton(
                  onPressed: () => _run(_closeSocket),
                  child: const Text('Close'),
                ),
                FilterChip(
                  label: const Text('enableWebSocket'),
                  selected: OneRequest.isWebSocketEnabled(),
                  onSelected: _toggleWebSocketKillSwitch,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
