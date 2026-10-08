import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_view_model.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository.dart';

class _MockRepository extends Mock implements PriceAuditRepository {}

const _milk = AuditEntry(
  barcode: '1',
  name: 'Milk',
  aisle: 'Dairy',
  systemPrice: Price(1250),
);
const _bread = AuditEntry(
  barcode: '2',
  name: 'Bread',
  aisle: 'Bakery',
  systemPrice: Price(500),
);

/// The view model is tested against the repository *interface*. A mock is
/// enough here because only the view model's reaction is under test.
void main() {
  late _MockRepository repository;
  late AuditViewModel viewModel;
  late List<Type> emitted;

  setUp(() {
    repository = _MockRepository();
    viewModel = AuditViewModel(repository: repository, aisle: 'Dairy');
    emitted = [];
    viewModel.addListener(() => emitted.add(viewModel.state.runtimeType));
  });

  test('load emits loading then the entries', () async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);

    await viewModel.load();

    expect(emitted, [AuditLoading, AuditLoaded]);
    expect((viewModel.state as AuditLoaded).entries, [_milk]);
  });

  test('load emits loading then the failure', () async {
    when(() => repository.loadAisle('Dairy'))
        .thenAnswer((_) async => throw const OfflineFailure());

    await viewModel.load();

    expect(emitted, [AuditLoading, AuditFailed]);
    expect((viewModel.state as AuditFailed).failure, isA<OfflineFailure>());
  });

  test('a response for an aisle the user already left is dropped', () async {
    final dairy = Completer<List<AuditEntry>>();
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) => dairy.future);
    when(() => repository.loadAisle('Bakery'))
        .thenAnswer((_) async => [_bread]);

    final firstLoad = viewModel.load();
    await viewModel.selectAisle('Bakery');
    dairy.complete([_milk]); // the slow answer arrives last
    await firstLoad;

    expect((viewModel.state as AuditLoaded).entries, [_bread]);
  });

  test('a response that arrives after dispose does not notify', () async {
    final dairy = Completer<List<AuditEntry>>();
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) => dairy.future);

    final load = viewModel.load();
    viewModel.dispose();
    dairy.complete([_milk]);

    await expectLater(load, completes);
  });

  test('recording a price replaces that entry only', () async {
    const checked = AuditEntry(
      barcode: '1',
      name: 'Milk',
      aisle: 'Dairy',
      systemPrice: Price(1250),
      shelfPrice: Price(1300),
    );
    when(() => repository.loadAisle('Dairy'))
        .thenAnswer((_) async => [_milk, _bread]);
    when(
      () => repository.recordShelfPrice(
        barcode: '1',
        shelfPrice: const Price(1300),
      ),
    ).thenAnswer((_) async => checked);
    await viewModel.load();

    await viewModel.recordShelfPrice('1', const Price(1300));

    expect((viewModel.state as AuditLoaded).entries, [checked, _bread]);
  });

  test('a failed save throws and leaves the list as it was', () async {
    when(() => repository.loadAisle('Dairy')).thenAnswer((_) async => [_milk]);
    when(
      () => repository.recordShelfPrice(
        barcode: any(named: 'barcode'),
        shelfPrice: any(named: 'shelfPrice'),
      ),
    ).thenAnswer((_) async => throw const TimeoutFailure());
    await viewModel.load();

    await expectLater(
      viewModel.recordShelfPrice('1', const Price(1300)),
      throwsA(isA<TimeoutFailure>()),
    );
    expect((viewModel.state as AuditLoaded).entries, [_milk]);
  });
}
