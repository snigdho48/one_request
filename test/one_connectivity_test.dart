import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_request/one_request.dart';

class _FakeSource implements ConnectivitySource {
  List<NetworkKind> current = const [NetworkKind.wifi];
  final StreamController<List<NetworkKind>> controller =
      StreamController<List<NetworkKind>>.broadcast();
  int listenCount = 0;

  @override
  Future<List<NetworkKind>> check() async => current;

  @override
  Stream<List<NetworkKind>> get onChanged {
    listenCount++;
    return controller.stream;
  }

  void emit(List<NetworkKind> next) {
    current = next;
    controller.add(next);
  }
}

void main() {
  late _FakeSource source;

  setUp(() {
    source = _FakeSource();
    OneRequest.resetConfig();
    ConnectivityWatch.debugSource = source;
  });

  tearDown(() async {
    OneRequest.clearConnectivity();
    ConnectivityWatch.debugSource = null;
    OneRequest.resetConfig();
    await source.controller.close();
  });

  test('connectivity is off until the app opts in', () async {
    expect(OneRequest.isConnectivityEnabled(), isFalse);
    expect(source.listenCount, 0);
    await Future<void>.delayed(Duration.zero);
    expect(source.listenCount, 0);
  });

  test('setConnectivity uses snackbar defaults and reports status', () async {
    OneRequest.setConnectivity();
    await Future<void>.delayed(Duration.zero);
    expect(OneRequest.isConnectivityEnabled(), isTrue);
    expect(OneRequest.connectivityUi, ConnectivityUi.snackbar);
    expect(OneRequest.connectivityStatus.online, isTrue);
    expect(source.listenCount, 1);

    final events = <ConnectivityStatus>[];
    OneRequest.setConnectivity(onChanged: events.add);
    source.emit(const [NetworkKind.none]);
    await Future<void>.delayed(Duration.zero);
    expect(OneRequest.connectivityStatus.online, isFalse);
    expect(events, isNotEmpty);
    expect(events.last.online, isFalse);
  });

  test('clearConnectivity and enableConnectivity: false turn it off', () async {
    OneRequest.setConnectivity(ui: ConnectivityUi.none);
    expect(OneRequest.isConnectivityEnabled(), isTrue);
    OneRequest.clearConnectivity();
    expect(OneRequest.isConnectivityEnabled(), isFalse);

    OneRequest.configure(enableConnectivity: true);
    expect(OneRequest.isConnectivityEnabled(), isTrue);
    OneRequest.configure(enableConnectivity: false);
    expect(OneRequest.isConnectivityEnabled(), isFalse);
  });

  test('configure omit leaves connectivity knobs unchanged', () {
    OneRequest.configure(
      enableConnectivity: true,
      connectivityUi: ConnectivityUi.popover,
      showOfflineNotice: false,
      showOnlineNotice: true,
    );
    OneRequest.configure(baseUrl: 'https://api.example.com');
    expect(OneRequest.isConnectivityEnabled(), isTrue);
    expect(OneRequest.connectivityUi, ConnectivityUi.popover);
    expect(ConnectivityWatch.showOffline, isFalse);
    expect(ConnectivityWatch.showOnline, isTrue);
  });

  Widget app() {
    return MaterialApp(
      builder: (context, child) => OneRequest.connectivityOverlay(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Scaffold(body: Text('home')),
    );
  }

  testWidgets('snackbar default shows offline text', (tester) async {
    source.current = const [NetworkKind.none];
    await tester.pumpWidget(app());
    OneRequest.setConnectivity(
      offlineMessage: 'No internet connection',
    );
    await tester.pump();
    await tester.pump();
    expect(OneRequest.connectivityStatus.online, isFalse);
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.byKey(const ValueKey('one_request_connectivity_snackbar')),
        findsOneWidget);
  });

  testWidgets('popover UI is used when asked', (tester) async {
    source.current = const [NetworkKind.none];
    await tester.pumpWidget(app());
    OneRequest.setConnectivity(
      ui: ConnectivityUi.popover,
      offlineMessage: 'You are offline',
    );
    await tester.pump();
    await tester.pump();
    expect(OneRequest.connectivityStatus.online, isFalse);
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.byKey(const ValueKey('one_request_connectivity_popover')),
        findsOneWidget);
  });

  testWidgets('custom builder replaces default UI', (tester) async {
    OneRequest.setConnectivity(
      builder: (context, status, child) {
        return Stack(
          children: [
            child,
            if (!status.online)
              const Align(
                alignment: Alignment.topCenter,
                child: Text('custom-offline'),
              ),
          ],
        );
      },
    );
    await tester.pumpWidget(app());
    source.emit(const [NetworkKind.none]);
    await tester.pump();
    expect(find.text('custom-offline'), findsOneWidget);
    expect(find.byKey(const ValueKey('one_request_connectivity_snackbar')),
        findsNothing);
  });

  testWidgets('ui none watches without drawing', (tester) async {
    var hits = 0;
    OneRequest.setConnectivity(
      ui: ConnectivityUi.none,
      onChanged: (_) => hits++,
    );
    await tester.pumpWidget(app());
    source.emit(const [NetworkKind.none]);
    await tester.pump();
    expect(OneRequest.connectivityStatus.online, isFalse);
    expect(hits, greaterThan(0));
    expect(find.text('No internet connection'), findsNothing);
  });

  testWidgets('wrap() still builds with connectivity off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: OneRequest.wrap(),
      home: const Scaffold(body: Text('home')),
    ));
    expect(find.text('home'), findsOneWidget);
  }, skip: kIsWeb);
}
