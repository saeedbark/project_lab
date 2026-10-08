import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/services/price_api.dart';

enum NetworkCondition { normal, slow, offline, serverError }

/// An in-memory stand-in for the real server.
///
/// It speaks the same JSON the real API would (prices are decimal strings,
/// keys are snake_case), so the DTO and the repository above it are doing
/// real work. [condition] can be flipped at any time to provoke each failure.
final class FakePriceApi implements PriceApi {
  FakePriceApi({
    this.trace = noTrace,
    this.latency = const Duration(milliseconds: 700),
    this.slowLatency = const Duration(seconds: 6),
  });

  final Trace trace;
  final Duration latency;
  final Duration slowLatency;

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
    return [
      for (final row in _rows)
        if (row['aisle'] == aisle) Map.of(row),
    ];
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
    return Map.of(row);
  }

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
