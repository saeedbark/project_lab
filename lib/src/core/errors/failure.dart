/// Everything that can go wrong below the UI, as a closed set.
///
/// Repositories translate transport-level exceptions into one of these, so
/// the layers above never see a status code or a socket error. Because the
/// class is `sealed`, a `switch` over a [Failure] is checked for
/// exhaustiveness: adding a new case here breaks every switch that forgot it.
sealed class Failure implements Exception {
  const Failure();
}

/// The device could not reach the server at all.
final class OfflineFailure extends Failure {
  const OfflineFailure();
}

/// The server was reached but did not answer in time.
final class TimeoutFailure extends Failure {
  const TimeoutFailure();
}

/// The server answered with a non-success status.
final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode);

  final int statusCode;
}

/// Anything we did not anticipate, e.g. a payload that does not parse.
///
/// Keeps the original [cause] for logs; the UI must not show it to the user.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.cause);

  final Object cause;
}
