import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';

/// The Riverpod counterpart of `AuditViewModel`.
///
/// There is no state class, no load id and no disposed flag: [build] returns
/// a future and Riverpod turns it into `AsyncValue<List<AuditEntry>>`,
/// discards results that arrive after disposal, and creates one instance per
/// aisle.
class AuditController extends AsyncNotifier<List<AuditEntry>> {
  AuditController(this.aisle);

  final String aisle;

  @override
  Future<List<AuditEntry>> build() {
    final trace = ref.watch(traceProvider);
    trace(TraceLayer.state, 'AuditController($aisle).build()');
    ref.onDispose(
      () => trace(TraceLayer.state, 'AuditController($aisle) disposed'),
    );
    return ref.watch(priceAuditRepositoryProvider).loadAisle(aisle);
  }

  /// Throws a `Failure` if the save fails; the list is left untouched.
  Future<void> recordShelfPrice(String barcode, Price shelfPrice) async {
    // `read`, not `watch`: this is a one-off call, not a dependency of build.
    final saved = await ref
        .read(priceAuditRepositoryProvider)
        .recordShelfPrice(barcode: barcode, shelfPrice: shelfPrice);

    // The user may have left this aisle while the request was in flight.
    if (!ref.mounted) return;
    final entries = state.value;
    if (entries == null) return;

    state = AsyncData([
      for (final entry in entries)
        if (entry.barcode == saved.barcode) saved else entry,
    ]);
  }
}
