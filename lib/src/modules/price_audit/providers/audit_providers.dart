import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_controller.dart';
import 'package:project_lab/src/modules/price_audit/services/price_api.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository_impl.dart';

/// The dependency graph of the feature, top to bottom. Each provider names
/// what it needs with `ref.watch`; nobody passes objects down by hand.

final traceProvider = Provider<Trace>((ref) => noTrace);

/// Has no sensible default, so it must be overridden where the app is
/// composed (a real client in production, a fake in the lab and in tests).
final priceApiProvider = Provider<PriceApi>(
  (ref) => throw UnimplementedError('Override priceApiProvider'),
);

/// Typed as the interface: what watches this cannot see the implementation.
final priceAuditRepositoryProvider = Provider<PriceAuditRepository>(
  (ref) => PriceAuditRepositoryImpl(
    api: ref.watch(priceApiProvider),
    trace: ref.watch(traceProvider),
  ),
);

/// One controller per aisle (`family`), destroyed when no widget is watching
/// that aisle any more (`autoDispose`).
///
/// Riverpod 3 retries a failed provider on its own, with backoff. It is
/// switched off here so that an error stays on screen until the user taps
/// Retry; retrying belongs in the network layer, where it can be selective.
final auditControllerProvider = AsyncNotifierProvider.autoDispose
    .family<AuditController, List<AuditEntry>, String>(
      AuditController.new,
      retry: (retryCount, error) => null,
    );
