/// The remote service, as the wire sees it: untyped JSON in, untyped JSON out.
///
/// Implementations throw [ApiException] for a non-success status and
/// [ConnectionException] when the server cannot be reached.
abstract interface class PriceApi {
  /// `GET /aisles/{aisle}/entries`
  Future<List<Map<String, Object?>>> fetchAisle(String aisle);

  /// `PUT /entries/{barcode}/shelf-price`
  Future<Map<String, Object?>> putShelfPrice(String barcode, String shelfPrice);
}

final class ApiException implements Exception {
  const ApiException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode)';
}

final class ConnectionException implements Exception {
  const ConnectionException();

  @override
  String toString() => 'ConnectionException';
}
