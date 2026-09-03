/// one_request 3.x example.
///
/// `request<T>()` throws [RequestException].
/// `send<T>()` returns `Either<String, T>` (Left = error, Right = data).
library;

import 'package:flutter/material.dart';
import 'package:one_request/one_request.dart';

void main() {
  OneRequest.configure(
    baseUrl: 'https://catfact.ninja',
    enableErrorLogger: true,
    enableResponseLogger: true,
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

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _api = OneRequest();
  String _result = 'Tap a button.';
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Preferred in apps: no fold, catch [RequestException].
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

  /// Either: Left = error, Right = data. Named fold.
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
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result, style: const TextStyle(fontSize: 16)),
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}
