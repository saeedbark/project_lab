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

/// The live counterpart of [auditControllerProvider]: the same
/// `AsyncValue<List<AuditEntry>>`, fed by a stream instead of a future.
///
/// There is no notifier. Riverpod calls `listen` on the stream, turns each
/// snapshot into `AsyncData` and an error event into `AsyncError` (keeping
/// the last snapshot), so nothing is left to write by hand. Saving goes
/// straight to the repository and the server's echo arrives through this
/// stream: the state has one writer.
///
/// `autoDispose` is what makes leaving an aisle close its socket: disposal
/// cancels the subscription. Without it a StreamProvider is almost never
/// destroyed, and every aisle ever opened would stay connected.
final liveAisleProvider = StreamProvider.autoDispose
    .family<List<AuditEntry>, String>(
      (ref, aisle) {
        final trace = ref.watch(traceProvider);
        trace(TraceLayer.state, 'liveAisleProvider($aisle) subscribes');
        // onCancel: the last widget stopped listening, either hidden (a
        // route covers it) or gone. Riverpod first *pauses* the stream
        // subscription. Disposal, which cancels it, follows only when the
        // listener was removed; a hidden widget still counts.
        ref
          ..onCancel(
            () => trace(
              TraceLayer.state,
              'liveAisleProvider($aisle): no '
              'listener, subscription paused',
            ),
          )
          ..onResume(
            () => trace(TraceLayer.state, 'liveAisleProvider($aisle) resumed'),
          )
          ..onDispose(
            () => trace(
              TraceLayer.state,
              'liveAisleProvider($aisle) '
              'disposed, subscription cancelled',
            ),
          );
        return ref.watch(priceAuditRepositoryProvider).watchAisle(aisle);
      },
      // A dropped feed stays dropped until the user taps Reconnect, for the
      // same reason as the controller above.
      retry: (retryCount, error) => null,
    );
