/// The remote service, as the wire sees it: untyped JSON in, untyped JSON out.
///
/// Implementations throw [ApiException] for a non-success status and
/// [ConnectionException] when the server cannot be reached.
abstract interface class PriceApi {
  /// `GET /aisles/{aisle}/entries`
  Future<List<Map<String, Object?>>> fetchAisle(String aisle);

  /// `PUT /entries/{barcode}/shelf-price`
  Future<Map<String, Object?>> putShelfPrice(String barcode, String shelfPrice);

  /// `WS /aisles/{aisle}/live`: the aisle's rows now, then again every time
  /// any of them changes on the server.
  ///
  /// A `Stream`, not a `Future`, because there is no last answer: the
  /// server keeps talking until the client cancels or the connection drops.
  /// A drop is one error event ([ConnectionException] or [ApiException]),
  /// after which the stream is done.
  Stream<List<Map<String, Object?>>> watchAisle(String aisle);
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
