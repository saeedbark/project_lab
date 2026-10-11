import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';

/// What the rest of the app may ask about price audits.
///
/// Providers and pages depend on this file only. The implementation and the
/// API client sit beside it in `services/` but are named in exactly one
/// place, where the app is composed, so either can be swapped without
/// touching anything above.
///
/// Every method fails with a [Failure] and nothing else: thrown from a
/// `Future`, emitted as an error event from a `Stream`.
abstract interface class PriceAuditRepository {
  /// The aisle as it is now: one answer.
  Future<List<AuditEntry>> loadAisle(String aisle);

  /// The aisle now, then again after every change, until cancelled.
  ///
  /// Nothing is opened until the stream is listened to, and cancelling the
  /// subscription closes the connection. A [Failure] arrives as an error
  /// event and ends the stream: watching again means listening again.
  Stream<List<AuditEntry>> watchAisle(String aisle);

  /// Records what the auditor read on the label and returns the saved entry.
  Future<AuditEntry> recordShelfPrice({
    required String barcode,
    required Price shelfPrice,
  });
}
