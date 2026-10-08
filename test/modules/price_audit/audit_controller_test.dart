import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository.dart';

class _MockRepository extends Mock implements PriceAuditRepository {}

const _milk = AuditEntry(
  barcode: '1',
  name: 'Milk',
  aisle: 'Dairy',
  systemPrice: Price(1250),
);
const _milkChecked = AuditEntry(
  barcode: '1',
  name: 'Milk',
  aisle: 'Dairy',
  systemPrice: Price(1250),
  shelfPrice: Price(1300),
);

/// No widgets: a [ProviderContainer] is the whole runtime. Overriding the
/// repository provider is the Riverpod form of constructor injection.
void main() {
  late _MockRepository repository;
  late ProviderContainer container;
  final dairy = auditControllerProvider('Dairy');

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer.test(
      overrides: [priceAuditRepositoryProvider.overrideWithValue(repository)],
    );
  });

  /// Keeps the autoDispose provider alive and records every state it takes.
  List<AsyncValue<List<AuditEntry>>> listen() {
    final states = <AsyncValue<List<AuditEntry>>>[];
    container.listen(
      dairy,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    return states;
  }

  test('first load: AsyncLoading, then AsyncData', () async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    final states = listen();

    await container.read(dairy.future);

    expect(states, [
      isA<AsyncLoading<List<AuditEntry>>>(),
      isA<AsyncData<List<AuditEntry>>>().having((s) => s.value, 'value', [
        _milk,
      ]),
    ]);
  });

  test('a failed first load is an AsyncError holding the Failure', () async {
    when(() => repository.loadAisle('Dairy'))
        .thenAnswer((_) async => throw const OfflineFailure());
    final states = listen();

    await expectLater(container.read(dairy.future), throwsA(anything));

    expect(states.last.error, isA<OfflineFailure>());
    expect(states.last.hasValue, isFalse);
  });

  test(
    'retrying a failed first load is an AsyncError with isLoading',
    () async {
      var online = false;
      when(() => repository.loadAisle('Dairy')).thenAnswer(
        (_) async => online ? [_milk] : throw const OfflineFailure(),
      );
      final states = listen();
      await expectLater(container.read(dairy.future), throwsA(anything));

      online = true;
      container.invalidate(dairy);
      await container.read(dairy.future);

      expect(states[2], isA<AsyncError<List<AuditEntry>>>());
      expect(states[2].isLoading, isTrue);
      expect(states[3].value, [_milk]);
    },
  );

  test('refresh keeps the data visible and only raises isLoading', () async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    final states = listen();
    await container.read(dairy.future);

    container.invalidate(dairy);
    await container.read(dairy.future);

    expect(states[2], isA<AsyncData<List<AuditEntry>>>());
    expect(states[2].isLoading, isTrue);
    expect(states[2].value, [_milk]);
    expect(states[3].isLoading, isFalse);
  });

  test(
    'a failed refresh is an AsyncError that still has the old data',
    () async {
      var online = true;
      when(() => repository.loadAisle('Dairy')).thenAnswer(
        (_) async => online ? [_milk] : throw const OfflineFailure(),
      );
      final states = listen();
      await container.read(dairy.future);

      online = false;
      container.invalidate(dairy);
      await expectLater(container.read(dairy.future), throwsA(anything));

      expect(states.last, isA<AsyncError<List<AuditEntry>>>());
      expect(states.last.error, isA<OfflineFailure>());
      expect(states.last.value, [_milk]);
    },
  );

  test('recording a price replaces that entry in the state', () async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    when(
      () => repository.recordShelfPrice(
        barcode: '1',
        shelfPrice: const Price(1300),
      ),
    ).thenAnswer((_) async => _milkChecked);
    listen();
    await container.read(dairy.future);

    await container
        .read(dairy.notifier)
        .recordShelfPrice('1', const Price(1300));

    expect(container.read(dairy).value, [_milkChecked]);
  });

  test('a failed save throws and the state stays AsyncData', () async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    when(
      () => repository.recordShelfPrice(
        barcode: any(named: 'barcode'),
        shelfPrice: any(named: 'shelfPrice'),
      ),
    ).thenAnswer((_) async => throw const TimeoutFailure());
    listen();
    await container.read(dairy.future);

    await expectLater(
      container.read(dairy.notifier).recordShelfPrice('1', const Price(1300)),
      throwsA(isA<TimeoutFailure>()),
    );
    expect(container.read(dairy), isA<AsyncData<List<AuditEntry>>>());
  });

  test('autoDispose: with no listener left, the controller is destroyed and '
      'a late save result is ignored', () async {
    final save = Completer<AuditEntry>();
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    when(
      () => repository.recordShelfPrice(
        barcode: '1',
        shelfPrice: const Price(1300),
      ),
    ).thenAnswer((_) => save.future);
    final subscription = container.listen(dairy, (_, _) {});
    await container.read(dairy.future);
    final pendingSave = container
        .read(dairy.notifier)
        .recordShelfPrice('1', const Price(1300));

    subscription.close();
    await container.pump(); // lets autoDispose run
    save.complete(_milkChecked);

    await expectLater(pendingSave, completes);
    expect(container.exists(dairy), isFalse);
  });

  test('family: each aisle gets its own controller and its own load', () async {
    when(() => repository.loadAisle(any())).thenAnswer((_) async => []);
    container.listen(auditControllerProvider('Dairy'), (_, _) {});
    container.listen(auditControllerProvider('Bakery'), (_, _) {});

    await container.read(auditControllerProvider('Bakery').future);

    verify(() => repository.loadAisle('Dairy')).called(1);
    verify(() => repository.loadAisle('Bakery')).called(1);
  });
}
