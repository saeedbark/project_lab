import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/modules/price_audit/pages/live_audit_page.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';
import 'package:project_lab/src/modules/price_audit/services/fake_price_api.dart';

/// The page over the real feed and repository: only the network is fake.
/// A mocked repository would need a hand-driven StreamController per test,
/// which is the fake server again, written worse.
void main() {
  late FakePriceApi api;
  late List<String> trace;
  final navigator = GlobalKey<NavigatorState>();

  setUp(() {
    trace = [];
    // Captured per test: a previous test's teardown must not write here.
    final log = trace;
    api = FakePriceApi(
      trace: (_, message) => log.add(message),
      latency: Duration.zero,
      repriceEvery: null,
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final log = trace;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priceApiProvider.overrideWithValue(api),
          traceProvider.overrideWithValue((_, message) => log.add(message)),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(
            body: LiveAuditPage(aisles: ['Dairy', 'Bakery']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder systemPrice(String price) =>
      find.textContaining('system $price', findRichText: true);

  testWidgets('a change on the server reaches the list without a request', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(systemPrice('12.50'), findsOneWidget);

    api.repriceNext(); // Fresh milk 12.50 → 13.00
    await tester.pumpAndSettle();

    expect(systemPrice('13.00'), findsOneWidget);
    expect(trace.where((line) => line.startsWith('GET')), isEmpty);
  });

  testWidgets('a saved price shows up through the feed\'s echo', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text('Fresh milk 1L'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Same as system'));
    await tester.pumpAndSettle();

    expect(find.text('Match'), findsOneWidget);
  });

  testWidgets('a dropped feed keeps the list, and Reconnect resubscribes', (
    tester,
  ) async {
    await pumpPage(tester);

    api.condition = NetworkCondition.offline;
    api.repriceNext();
    await tester.pumpAndSettle();

    expect(find.textContaining('Live updates stopped'), findsOneWidget);
    expect(find.text('Fresh milk 1L'), findsOneWidget);

    api.condition = NetworkCondition.normal;
    await tester.tap(find.text('Reconnect'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Live updates stopped'), findsNothing);
    // The new subscription's first snapshot already has the change that
    // arrived while the feed was down.
    expect(systemPrice('13.00'), findsOneWidget);
  });

  testWidgets('a failed first connection shows the error, and Retry works', (
    tester,
  ) async {
    api.condition = NetworkCondition.serverError;
    await pumpPage(tester);
    expect(find.textContaining('The server had a problem'), findsOneWidget);

    api.condition = NetworkCondition.normal;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Fresh milk 1L'), findsOneWidget);
  });

  testWidgets('switching aisle closes the old feed', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Bakery'));
    await tester.pumpAndSettle();

    expect(find.text('White bread'), findsOneWidget);
    // In this order: Riverpod pauses, then disposes, which cancels.
    expect(
      trace
          .where((line) => line.contains('Dairy'))
          .skipWhile((line) => !line.contains('no listener')),
      [
        'liveAisleProvider(Dairy): no listener, subscription paused',
        'WS /aisles/Dairy/live paused: snapshots are buffered',
        'WS /aisles/Dairy/live closed by the client',
        'liveAisleProvider(Dairy) disposed, subscription cancelled',
      ],
    );
    expect(api.hasLiveClients, isTrue, reason: 'Bakery is still open');
  });

  testWidgets('a covering route pauses the feed; going back delivers what '
      'was buffered', (tester) async {
    await pumpPage(tester);

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    expect(
      trace,
      contains('WS /aisles/Dairy/live paused: snapshots are buffered'),
    );

    api.repriceNext();
    await tester.pumpAndSettle();
    expect(
      trace,
      isNot(contains('WS /aisles/Dairy/live closed by the client')),
    );

    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(trace, contains('WS /aisles/Dairy/live resumed'));
    expect(systemPrice('13.00'), findsOneWidget);
  });
}
