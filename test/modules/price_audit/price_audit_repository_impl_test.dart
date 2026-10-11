import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/services/fake_price_api.dart';
import 'package:project_lab/src/modules/price_audit/services/price_api.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository_impl.dart';

/// A repository test answers one question: given what the wire does, what
/// does the rest of the app see? The fake server plays the wire.
void main() {
  late FakePriceApi api;
  late PriceAuditRepositoryImpl repository;

  setUp(() {
    api = FakePriceApi(
      latency: Duration.zero,
      slowLatency: const Duration(milliseconds: 50),
      repriceEvery: null,
    );
    repository = PriceAuditRepositoryImpl(
      api: api,
      timeout: const Duration(milliseconds: 10),
    );
  });

  test('maps wire rows to domain entries', () async {
    final entries = await repository.loadAisle('Dairy');

    expect(entries, hasLength(4));
    expect(
      entries.first,
      const AuditEntry(
        barcode: '6281001',
        name: 'Fresh milk 1L',
        aisle: 'Dairy',
        systemPrice: Price(1250),
      ),
    );
  });

  test('a recorded shelf price is returned and persisted', () async {
    final saved = await repository.recordShelfPrice(
      barcode: '6281001',
      shelfPrice: const Price(1300),
    );
    final reloaded = await repository.loadAisle('Dairy');

    expect(saved.status, isA<Mismatch>());
    expect(reloaded.first, saved);
  });

  group('transport errors leave as Failures', () {
    test('no connection → OfflineFailure', () {
      api.condition = NetworkCondition.offline;

      expect(repository.loadAisle('Dairy'), throwsA(isA<OfflineFailure>()));
    });

    test('non-success status → ServerFailure with the code', () {
      api.condition = NetworkCondition.serverError;

      expect(
        repository.loadAisle('Dairy'),
        throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 503)),
      );
    });

    test('slow server → TimeoutFailure', () {
      api.condition = NetworkCondition.slow;

      expect(repository.loadAisle('Dairy'), throwsA(isA<TimeoutFailure>()));
    });

    test('unknown barcode → ServerFailure 404', () {
      expect(
        repository.recordShelfPrice(
          barcode: 'nope',
          shelfPrice: const Price(100),
        ),
        throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'code', 404)),
      );
    });

    test('a payload we cannot parse → UnexpectedFailure', () {
      final repository = PriceAuditRepositoryImpl(api: _MalformedApi());

      expect(repository.loadAisle('Dairy'), throwsA(isA<UnexpectedFailure>()));
    });
  });

  group('watchAisle', () {
    test('each snapshot arrives as domain entries', () async {
      final snapshots = <List<AuditEntry>>[];
      final subscription = repository.watchAisle('Dairy').listen(snapshots.add);
      await pumpEventQueue();

      api.repriceNext(); // Fresh milk 12.50 → 13.00
      await pumpEventQueue();

      expect(snapshots, hasLength(2));
      expect(snapshots.last.first.systemPrice, const Price(1300));
      await subscription.cancel();
    });

    test('a dropped feed is one Failure, then the stream is done', () async {
      final events = <Object>[];
      repository
          .watchAisle('Dairy')
          .listen(
            events.add,
            onError: events.add,
            onDone: () => events.add('done'),
          );
      await pumpEventQueue();

      api.condition = NetworkCondition.offline;
      api.repriceNext();
      await pumpEventQueue();

      expect(events, [isA<List<AuditEntry>>(), isA<OfflineFailure>(), 'done']);
    });

    test('a failed handshake is a Failure with no data before it', () {
      api.condition = NetworkCondition.serverError;

      expect(
        repository.watchAisle('Dairy'),
        emitsInOrder([emitsError(isA<ServerFailure>()), emitsDone]),
      );
    });

    // The pipeline adds no subscription of its own: pausing and cancelling
    // the repository's stream act on the API's feed directly.
    test('cancel goes straight through to the feed', () async {
      final subscription = repository.watchAisle('Dairy').listen((_) {});
      await pumpEventQueue();
      expect(api.hasLiveClients, isTrue);

      await subscription.cancel();

      expect(api.hasLiveClients, isFalse);
    });
  });
}

class _MalformedApi implements PriceApi {
  @override
  Future<List<Map<String, Object?>>> fetchAisle(String aisle) async => [
    {'barcode': '1', 'name': 'Milk', 'aisle': aisle, 'system_price': 12.5},
  ];

  @override
  Future<Map<String, Object?>> putShelfPrice(String barcode, String price) =>
      throw UnimplementedError();

  @override
  Stream<List<Map<String, Object?>>> watchAisle(String aisle) =>
      throw UnimplementedError();
}
