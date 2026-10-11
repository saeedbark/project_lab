import 'dart:async';

import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/services/price_api.dart';

enum NetworkCondition { normal, slow, offline, serverError }

/// An in-memory stand-in for the real server.
///
/// It speaks the same JSON the real API would (prices are decimal strings,
/// keys are snake_case), so the DTO and the repository above it are doing
/// real work. [condition] can be flipped at any time to provoke each failure.
///
/// For the live feed it also plays head office: while at least one client
/// is watching, it reprices one product every [repriceEvery].
final class FakePriceApi implements PriceApi {
  FakePriceApi({
    this.trace = noTrace,
    this.latency = const Duration(milliseconds: 700),
    this.slowLatency = const Duration(seconds: 6),
    this.repriceEvery = const Duration(seconds: 5),
  });

  final Trace trace;
  final Duration latency;
  final Duration slowLatency;

  /// Null turns the timer off; tests call [repriceNext] themselves.
  final Duration? repriceEvery;

  NetworkCondition condition = NetworkCondition.normal;

  static const aisles = ['Dairy', 'Bakery', 'Drinks'];

  final List<Map<String, Object?>> _rows = [
    _row('6281001', 'Fresh milk 1L', 'Dairy', '12.50'),
    _row('6281002', 'Yogurt 500g', 'Dairy', '8.00'),
    _row('6281003', 'Butter 200g', 'Dairy', '21.75'),
    _row('6281004', 'Cheddar 250g', 'Dairy', '34.00'),
    _row('6282001', 'White bread', 'Bakery', '5.00'),
    _row('6282002', 'Croissant x4', 'Bakery', '18.00'),
    _row('6282003', 'Date cake', 'Bakery', '27.50'),
    _row('6283001', 'Water 1.5L', 'Drinks', '3.00'),
    _row('6283002', 'Orange juice 1L', 'Drinks', '14.25'),
    _row('6283003', 'Cola 330ml', 'Drinks', '4.50'),
  ];

  static Map<String, Object?> _row(
    String barcode,
    String name,
    String aisle,
    String price,
  ) => {
    'barcode': barcode,
    'name': name,
    'aisle': aisle,
    'system_price': price,
    'shelf_price': null,
  };

  @override
  Future<List<Map<String, Object?>>> fetchAisle(String aisle) async {
    await _simulateNetwork('GET /aisles/$aisle/entries');
    return _snapshot(aisle);
  }

  @override
  Future<Map<String, Object?>> putShelfPrice(
    String barcode,
    String shelfPrice,
  ) async {
    await _simulateNetwork('PUT /entries/$barcode/shelf-price');
    final row = _rows.firstWhere(
      (row) => row['barcode'] == barcode,
      orElse: () => throw const ApiException(404),
    );
    row['shelf_price'] = shelfPrice;
    _changes.add(row['aisle']! as String);
    return Map.of(row);
  }

  /// The server's internal "this aisle changed" signal.
  ///
  /// Broadcast, because every open feed listens to the same signal at once.
  /// The other half of broadcast is why a feed starts with a snapshot: an
  /// event sent while nobody listens is gone, and a late listener only hears
  /// what happens after it subscribed. There is no history to replay.
  ///
  /// On a broadcast controller `onListen` means "first listener" and
  /// `onCancel` means "last listener left", which is exactly when head
  /// office should start and stop repricing.
  late final _changes = StreamController<String>.broadcast(
    onListen: _startRepricing,
    onCancel: _stopRepricing,
  );
  Timer? _repricing;
  int _repriced = 0;

  /// Whether any feed is open. Tests use it to prove that cancelling a
  /// subscription really closes the connection.
  bool get hasLiveClients => _changes.hasListener;

  @override
  Stream<List<Map<String, Object?>>> watchAisle(String aisle) {
    final request = 'WS /aisles/$aisle/live';
    StreamSubscription<String>? changes;
    // Assigned below; the callbacks need to refer to it.
    late final StreamController<List<Map<String, Object?>>> feed;

    void drop(Exception error) {
      trace(TraceLayer.dataSource, '$request dropped: $error');
      changes?.cancel();
      feed
        ..addError(error)
        ..close();
    }

    Future<void> open() async {
      try {
        await _simulateNetwork(request);
      } on Exception catch (error) {
        if (feed.hasListener) drop(error);
        return;
      }
      // The client may have cancelled during the handshake. Subscribing to
      // [_changes] now would keep head office repricing for nobody.
      if (!feed.hasListener) return;
      feed.add(_snapshot(aisle));
      changes = _changes.stream.listen((changed) {
        // A real socket notices a dead network on its next frame; this one
        // checks on every signal, whichever aisle it is for.
        if (condition == NetworkCondition.offline) {
          drop(const ConnectionException());
        } else if (changed == aisle) {
          feed.add(_snapshot(aisle));
        }
      });
    }

    // A controller rather than an `async*` generator: the events come from
    // callbacks (a timer, a write), and cancelling must close the connection
    // at once. An `async*` body waiting in `await for` only notices a cancel
    // when its source next emits, which for a quiet aisle may be never.
    // `live_feed_test.dart` pins that behaviour down.
    feed = StreamController(
      // Calling watchAisle opens nothing. The connection starts on the first
      // listen: a Stream is a recipe until someone subscribes.
      onListen: open,
      onPause: () => trace(
        TraceLayer.dataSource,
        '$request paused: snapshots are buffered',
      ),
      onResume: () => trace(TraceLayer.dataSource, '$request resumed'),
      // Also runs after the server closes the feed itself (a drop), once the
      // done event has been delivered. Only a cancel finds it still open.
      onCancel: () {
        if (!feed.isClosed) {
          trace(TraceLayer.dataSource, '$request closed by the client');
        }
        return changes?.cancel();
      },
    );
    return feed.stream;
  }

  /// Head office changes one system price, cycling through the products:
  /// up 0.50 on the first pass, back down on the next.
  void repriceNext() {
    final row = _rows[_repriced % _rows.length];
    final step = (_repriced ~/ _rows.length).isEven ? 50 : -50;
    _repriced++;
    final price = Price.tryParse(row['system_price']! as String)!;
    row['system_price'] = Price(price.minorUnits + step).format();
    trace(
      TraceLayer.dataSource,
      'head office: ${row['name']} is now ${row['system_price']}',
    );
    _changes.add(row['aisle']! as String);
  }

  void _startRepricing() {
    final every = repriceEvery;
    if (every == null) return;
    trace(TraceLayer.dataSource, 'first live client: repricing started');
    _repricing = Timer.periodic(every, (_) => repriceNext());
  }

  void _stopRepricing() {
    final repricing = _repricing;
    if (repricing == null) return;
    trace(TraceLayer.dataSource, 'no live clients: repricing stopped');
    repricing.cancel();
    _repricing = null;
  }

  List<Map<String, Object?>> _snapshot(String aisle) => [
    for (final row in _rows)
      if (row['aisle'] == aisle) Map.of(row),
  ];

  Future<void> _simulateNetwork(String request) async {
    // Read once: the condition the request *started* under decides its fate.
    final condition = this.condition;
    trace(TraceLayer.dataSource, '$request  (network: ${condition.name})');
    await Future<void>.delayed(
      condition == NetworkCondition.slow ? slowLatency : latency,
    );
    switch (condition) {
      case NetworkCondition.offline:
        throw const ConnectionException();
      case NetworkCondition.serverError:
        throw const ApiException(503);
      case NetworkCondition.normal || NetworkCondition.slow:
        trace(TraceLayer.dataSource, '200 OK  $request');
    }
  }
}
