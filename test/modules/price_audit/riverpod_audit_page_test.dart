import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/pages/riverpod_audit_page.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository.dart';

class _MockRepository extends Mock implements PriceAuditRepository {}

const _milk = AuditEntry(
  barcode: '1',
  name: 'Milk',
  aisle: 'Dairy',
  systemPrice: Price(1250),
);

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [priceAuditRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(body: RiverpodAuditPage(aisles: ['Dairy', 'Bakery'])),
        ),
      ),
    );
  }

  testWidgets('loading shows a spinner, then data shows the list', (
    tester,
  ) async {
    final response = Completer<List<AuditEntry>>();
    when(() => repository.loadAisle('Dairy'))
        .thenAnswer((_) => response.future);

    await pumpPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete([_milk]);
    await tester.pump();
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Not checked'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failure shows its message, and Retry loads again', (
    tester,
  ) async {
    var online = false;
    when(
      () => repository.loadAisle('Dairy'),
    ).thenAnswer((_) async => online ? [_milk] : throw const OfflineFailure());

    await pumpPage(tester);
    await tester.pump();
    expect(find.textContaining('No connection'), findsOneWidget);

    online = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('during a refresh the list stays and a progress bar appears', (
    tester,
  ) async {
    var response = Completer<List<AuditEntry>>()..complete([_milk]);
    when(() => repository.loadAisle('Dairy'))
        .thenAnswer((_) => response.future);
    await pumpPage(tester);
    await tester.pump();

    response = Completer();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(find.text('Milk'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    response.complete([_milk]);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a failed refresh keeps the list on screen', (tester) async {
    var online = true;
    when(
      () => repository.loadAisle('Dairy'),
    ).thenAnswer((_) async => online ? [_milk] : throw const OfflineFailure());
    await pumpPage(tester);
    await tester.pump();

    online = false;
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.textContaining('No connection'), findsNothing);
  });

  testWidgets('switching aisle loads that aisle', (tester) async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    when(() => repository.loadAisle('Bakery')).thenAnswer((_) async => []);
    await pumpPage(tester);
    await tester.pump();

    await tester.tap(find.text('Bakery'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsNothing);
    verify(() => repository.loadAisle('Bakery')).called(1);
  });

  testWidgets('a failed save shows a snackbar and keeps the entry', (
    tester,
  ) async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    when(
      () => repository.recordShelfPrice(
        barcode: '1',
        shelfPrice: const Price(1250),
      ),
    ).thenAnswer((_) async => throw const TimeoutFailure());
    await pumpPage(tester);
    await tester.pump();

    await tester.tap(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Same as system'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Not saved'), findsOneWidget);
    expect(find.text('Not checked'), findsOneWidget);
  });
}
