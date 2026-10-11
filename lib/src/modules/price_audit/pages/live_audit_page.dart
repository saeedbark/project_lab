import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';
import 'package:project_lab/src/modules/price_audit/widgets/aisle_picker.dart';
import 'package:project_lab/src/modules/price_audit/widgets/audit_list_view.dart';
import 'package:project_lab/src/widgets/failure_view.dart';

/// The audit screen over a live feed. Compare with `RiverpodAuditPage`: the
/// same `AsyncValue` switch, but no Refresh button, because the data
/// refreshes itself, and a Reconnect banner, because a stream can fail
/// *after* it has delivered data.
class LiveAuditPage extends ConsumerStatefulWidget {
  const LiveAuditPage({super.key, required this.aisles});

  final List<String> aisles;

  @override
  ConsumerState<LiveAuditPage> createState() => _LiveAuditPageState();
}

class _LiveAuditPageState extends ConsumerState<LiveAuditPage> {
  late String _aisle = widget.aisles.first;

  @override
  Widget build(BuildContext context) {
    final provider = liveAisleProvider(_aisle);
    final live = ref.watch(provider);
    ref.read(traceProvider)(TraceLayer.ui, 'build ← ${_describe(live)}');

    // Reconnecting is resubscribing. The old stream is over; invalidate
    // builds a new one, which starts with a fresh snapshot, so whatever
    // changed while disconnected is not lost.
    void reconnect() => ref.invalidate(provider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: AislePicker(
            aisles: widget.aisles,
            selected: _aisle,
            onSelected: (aisle) => setState(() => _aisle = aisle),
          ),
        ),
        Expanded(
          // Same order as the Future version, for the same reason: a stream
          // that dropped is an AsyncError that still carries the last list.
          child: switch (live) {
            AsyncValue(:final value?) => Column(
              children: [
                if (live.error case final Failure failure)
                  _FeedStoppedBanner(
                    failure: failure,
                    reconnecting: live.isLoading,
                    onReconnect: reconnect,
                  ),
                Expanded(
                  child: AuditListView(
                    entries: value,
                    // No state update here: the server echoes the saved row
                    // through the feed, and that is what changes the list.
                    onRecord: (barcode, shelfPrice) => ref
                        .read(priceAuditRepositoryProvider)
                        .recordShelfPrice(
                          barcode: barcode,
                          shelfPrice: shelfPrice,
                        ),
                  ),
                ),
              ],
            ),
            AsyncValue(error: final Failure failure) => FailureView(
              failure: failure,
              onRetry: reconnect,
              retrying: live.isLoading,
            ),
            AsyncValue(:final error?, :final stackTrace?) =>
              Error.throwWithStackTrace(error, stackTrace),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }

  static String _describe(AsyncValue<List<Object?>> value) => switch (value) {
    AsyncValue(:final value?, error: _?) =>
      'AsyncError, still showing ${value.length} entries',
    AsyncData(:final value) => 'AsyncData (${value.length} entries)',
    AsyncError() => 'AsyncError',
    AsyncLoading() => 'AsyncLoading',
  };
}

class _FeedStoppedBanner extends StatelessWidget {
  const _FeedStoppedBanner({
    required this.failure,
    required this.reconnecting,
    required this.onReconnect,
  });

  final Failure failure;
  final bool reconnecting;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Live updates stopped. ${failureMessage(failure)}',
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: reconnecting ? null : onReconnect,
              child: Text(reconnecting ? 'Reconnecting…' : 'Reconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
