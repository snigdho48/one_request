import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_request/one_request.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('OneRequest Integration/Widget Tests', () {
    late OneRequest request;

    setUp(() {
      request = OneRequest();
      OneRequest.loadingconfig();
      OneRequest.resetConfig();
      OneRequest.resetErrorHandler();
      LoadingStuff.resetCustomBuilders();
    });

    testWidgets('shows loading and success overlay on GET success',
        (WidgetTester tester) async {
      // Use a test widget
      await tester.pumpWidget(MaterialApp(
        builder: OneRequest.initLoading,
        home: Scaffold(
          body: TestRequestWidget(
            request: request,
            url: 'https://catfact.ninja/fact',
            expectSuccess: true,
          ),
        ),
      ));
      // Tap the button to trigger request
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start loading
      await tester.pump(const Duration(seconds: 2)); // Wait for response
      expect(find.text('Cats are cool!'), findsOneWidget);
    });

    testWidgets('shows loading and error overlay on GET error',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        builder: OneRequest.initLoading,
        home: Scaffold(
          body: TestRequestWidget(
            request: request,
            url: 'https://invalid-url-that-will-fail.com/fact',
            expectSuccess: false,
          ),
        ),
      ));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start loading
      await tester.pump(const Duration(seconds: 2)); // Wait for response
      expect(find.textContaining('error', findRichText: true), findsOneWidget);
    });
  });
}

class TestRequestWidget extends StatefulWidget {
  final OneRequest request;
  final String url;
  final bool expectSuccess;
  const TestRequestWidget({
    required this.request,
    required this.url,
    required this.expectSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<TestRequestWidget> createState() => _TestRequestWidgetState();
}

class _TestRequestWidgetState extends State<TestRequestWidget> {
  String result = '';

  Future<void> _makeRequest() async {
    // Use OneRequest to make the actual request
    final response = await widget.request.send<Map<String, dynamic>>(
      url: widget.url,
      method: RequestType.GET,
      loader: true,
      resultOverlay: true,
    );

    response.fold(
      (data) => setState(() => result = data['fact'] ?? 'No fact'),
      (error) => setState(() => result = 'error: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (result.isNotEmpty) Text(result),
        ElevatedButton(
          onPressed: _makeRequest,
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}
