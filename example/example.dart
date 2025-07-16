// Example usage of OneRequest with Either for error handling
//
// This example demonstrates how to use the OneRequest package to make HTTP requests in Flutter.
// It uses the Either type from the either_dart package to handle both success and error cases in a clear, type-safe way.
//
// What is Either?
// - Either is a type that can hold one of two values: a success (called Left) or an error (called Right).
// - This means every request returns a result you MUST handle: either the data you want, or an error message.
// - This avoids crashes and makes your code safer and easier to read!
//
// In this example, you'll see:
// - How to make GET, POST, batch, and file upload requests
// - How to handle results using Either
// - How to show results or errors in the UI

import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:one_request/one_request.dart';
import 'package:either_dart/either.dart'; // We use Either for safe result handling

void main() async {
  // Set up global loading indicator and error widgets (optional)
  OneRequest.loadingconfig(
    backgroundColor: Colors.amber,
    indicator: const CircularProgressIndicator(),
    indicatorColor: Colors.red,
    progressColor: Colors.red,
    textColor: Colors.red,
    success: const Icon(Icons.check, color: Colors.green),
    error: const Icon(Icons.error, color: Colors.red),
    info: const Icon(Icons.info, color: Colors.blue),
  );

  // Set up global API config (base URL, headers, etc.)
  OneRequest.configure(
    baseUrl: 'https://catfact.ninja',
    headers: {'X-Global-Header': 'global'},
  );

  // Optional: Custom error handler and logger
  OneRequest.setErrorHandler(
    handler: (body, status, url) => body['message'] ?? 'Unknown error',
    logger: (error, stack) => print('Logged error: $error'),
  );

  // Optional: Custom loading/error widgets and localization
  LoadingStuff.setCustomBuilders(
    loadingBuilder: (context, status) => CircularProgressIndicator(),
    errorBuilder: (context, message) => Icon(Icons.error, color: Colors.red),
    localization: (msg) => 'Localized: $msg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: OneRequest.initLoading,
      title: 'OneRequest Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'OneRequest Feature Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _result = '';
  bool _loading = false;

  // This function takes an Either value (from either_dart), which represents either a success (Left) or an error (Right).
  // Purpose: To handle both success and error cases explicitly, updating the UI accordingly.
  //
  // How it works:
  // - If the request succeeded, value.left contains the data (e.g., a Map)
  // - If the request failed, value.right contains the error message (String)
  void _showResult(Either<dynamic, String> value) {
    setState(() {
      value.fold(
        (data) => _result = data.toString(), // Success: show the data
        (error) => _result = 'Error: $error', // Error: show the error message
      );
    });
  }

  // Type-safe GET request
  // Purpose: Demonstrates a GET request that returns an Either, allowing explicit handling of success/error.
  //
  // Steps:
  // 1. Make the request (returns Either)
  // 2. Pass the result to _showResult, which updates the UI
  Future<void> _getFact() async {
    setState(() => _loading = true);
    final req = OneRequest();
    // The send method returns Either<Map<String, dynamic>, String>
    // - Left: the response data (Map)
    // - Right: the error message (String)
    final value = await req.send<Map<String, dynamic>>(
      url: '/fact',
      method: RequestType.GET,
      loader: true,
      resultOverlay: true,
    );
    _showResult(value); // Handles both success and error
    setState(() => _loading = false);
  }

  // Type-safe POST request
  // Purpose: Shows POST request with Either result for robust error handling.
  Future<void> _postExample() async {
    setState(() => _loading = true);
    final req = OneRequest();
    final value = await req.send<Map<String, dynamic>>(
      url: '/post',
      method: RequestType.POST,
      body: {'foo': 'bar'},
      loader: true,
      resultOverlay: true,
    );
    _showResult(value); // Handles both success and error
    setState(() => _loading = false);
  }

  // GET with cache
  // Purpose: Demonstrates caching with Either result, so errors (including cache misses) are handled explicitly.
  Future<void> _getWithCache() async {
    setState(() => _loading = true);
    final req = OneRequest();
    final value = await req.send<Map<String, dynamic>>(
      url: '/fact',
      method: RequestType.GET,
      useCache: true, // Try to use cached result if available
      loader: true,
      resultOverlay: true,
    );
    _showResult(value); // Handles both success and error
    setState(() => _loading = false);
  }

  // Batch requests
  // Purpose: Shows how to handle multiple requests in parallel, each returning an Either for individual error/success handling.
  //
  // Steps:
  // 1. Call OneRequest.batch, which returns a List of Either results
  // 2. For each result, check if it's a success (isLeft) or error (isRight)
  Future<void> _batchRequests() async {
    setState(() => _loading = true);
    final results = await OneRequest.batch<Map<String, dynamic>>([
      {
        'url': '/fact',
        'method': RequestType.GET,
        'useCache': true,
      },
      {
        'url': '/fact',
        'method': RequestType.GET,
      },
    ], maxRetries: 1, retryDelay: Duration(milliseconds: 500), exponentialBackoff: true);
    setState(() {
      // Each result is an Either, so you can check .isLeft (success) or .isRight (error)
      _result = results
          .asMap()
          .entries
          .map((e) => 'Batch ${e.key + 1}: '
              '${e.value.isLeft ? 'Success: ' + e.value.left.toString() : 'Error: ' + e.value.right.toString()}')
          .join('\n');
      _loading = false;
    });
  }

  // Retry logic
  // Purpose: Demonstrates retrying a request, with Either ensuring all outcomes (including final failure) are handled.
  Future<void> _retryExample() async {
    setState(() => _loading = true);
    final req = OneRequest();
    final value = await req.send<Map<String, dynamic>>(
      url: '/fact',
      method: RequestType.GET,
      maxRetries: 2, // Will retry up to 2 times if it fails
      retryDelay: Duration(milliseconds: 500),
      loader: true,
      resultOverlay: true,
    );
    _showResult(value); // Handles both success and error
    setState(() => _loading = false);
  }

  // File upload (simulated)
  // Purpose: Shows file upload with Either result, so upload errors are handled as part of the result, not via exceptions.
  Future<void> _fileUpload() async {
    setState(() => _loading = true);
    final req = OneRequest();
    final filebytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
    final value = await req.send<Map<String, dynamic>>(
      url: '/upload',
      method: RequestType.POST,
      formData: true,
      body: {
        'file': [
          req.file(file: File('path'), filename: 'file'),
          req.fileFromByte(filebyte: filebytes),
          req.fileFormString(filestring: 'fileString'),
        ],
      },
      loader: true,
      resultOverlay: true,
    );
    _showResult(value); // Handles both success and error
    setState(() => _loading = false);
  }

  // Clear cache
  // Purpose: Shows how to clear the request cache and update the UI.
  void _clearCache() {
    OneRequest.clearCache();
    setState(() => _result = 'Cache cleared!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading) const LinearProgressIndicator(),
            Text('Result:', style: Theme.of(context).textTheme.titleMedium),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _getFact, child: const Text('GET (Type-safe)')),
                ElevatedButton(onPressed: _postExample, child: const Text('POST (Type-safe)')),
                ElevatedButton(onPressed: _getWithCache, child: const Text('GET with Cache')),
                ElevatedButton(onPressed: _batchRequests, child: const Text('Batch Requests')),
                ElevatedButton(onPressed: _retryExample, child: const Text('Retry Logic')),
                ElevatedButton(onPressed: _fileUpload, child: const Text('File Upload')),
                ElevatedButton(onPressed: _clearCache, child: const Text('Clear Cache')),
              ],
            ),
            const SizedBox(height: 8),
            const Text('See code comments for feature explanations.'),
          ],
        ),
      ),
    );
  }
}
