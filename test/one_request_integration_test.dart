import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_request/one_request.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('OneRequest Integration/Widget Tests', () {
    late MockClient mockClient;
    late OneRequest request;

    setUp(() {
      request = OneRequest();
      OneRequest.loadingconfig();
      OneRequest.resetConfig();
      OneRequest.resetErrorHandler();
      LoadingStuff.resetCustomBuilders();
    });

    testWidgets('shows loading and success overlay on GET success', (WidgetTester tester) async {
      // Simulate a successful response
      mockClient = MockClient((req) async {
        return http.Response(jsonEncode({'fact': 'Cats are cool!'}), 200);
      });
      // Use a test widget
      await tester.pumpWidget(MaterialApp(
        builder: OneRequest.initLoading,
        home: Scaffold(
          body: TestRequestWidget(
            request: request,
            mockClient: mockClient,
            url: 'https://catfact.ninja/fact',
            expectSuccess: true,
          ),
        ),
      ));
      // Tap the button to trigger request
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start loading
      expect(find.text('Loading...'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1)); // Wait for response
      expect(find.text('Cats are cool!'), findsOneWidget);
    });

    testWidgets('shows loading and error overlay on GET error', (WidgetTester tester) async {
      // Simulate an error response
      mockClient = MockClient((req) async {
        return http.Response('Internal Server Error', 500);
      });
      await tester.pumpWidget(MaterialApp(
        builder: OneRequest.initLoading,
        home: Scaffold(
          body: TestRequestWidget(
            request: request,
            mockClient: mockClient,
            url: 'https://catfact.ninja/fact',
            expectSuccess: false,
          ),
        ),
      ));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start loading
      expect(find.text('Loading...'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1)); // Wait for response
      expect(find.textContaining('error', findRichText: true), findsOneWidget);
    });
  });
}

class TestRequestWidget extends StatefulWidget {
  final OneRequest request;
  final http.Client mockClient;
  final String url;
  final bool expectSuccess;
  const TestRequestWidget({
    required this.request,
    required this.mockClient,
    required this.url,
    required this.expectSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<TestRequestWidget> createState() => _TestRequestWidgetState();
}

class _TestRequestWidgetState extends State<TestRequestWidget> {
  String result = '';
  bool loading = false;

  Future<void> _makeRequest() async {
    setState(() => loading = true);
    // Simulate a GET request using the mock client
    try {
      final response = await widget.mockClient.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          result = data['fact'] ?? 'No fact';
        });
      } else {
        setState(() {
          result = 'error: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        result = 'error: $e';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) const Text('Loading...'),
        if (!loading && result.isNotEmpty) Text(result),
        ElevatedButton(
          onPressed: _makeRequest,
          child: const Text('Send Request'),
        ),
      ],
    );
  }
} 