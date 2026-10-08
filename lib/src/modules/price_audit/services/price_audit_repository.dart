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
/// Both methods throw a [Failure] and nothing else.
abstract interface class PriceAuditRepository {
  Future<List<AuditEntry>> loadAisle(String aisle);

  /// Records what the auditor read on the label and returns the saved entry.
  Future<AuditEntry> recordShelfPrice({
    required String barcode,
    required Price shelfPrice,
  });
}
