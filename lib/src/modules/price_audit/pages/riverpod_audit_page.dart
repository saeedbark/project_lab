import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';
import 'package:project_lab/src/modules/price_audit/widgets/aisle_picker.dart';
import 'package:project_lab/src/modules/price_audit/widgets/audit_list_view.dart';
import 'package:project_lab/src/widgets/failure_view.dart';

class RiverpodAuditPage extends ConsumerStatefulWidget {
  const RiverpodAuditPage({super.key, required this.aisles});

  final List<String> aisles;

  @override
  ConsumerState<RiverpodAuditPage> createState() => _RiverpodAuditPageState();
}

class _RiverpodAuditPageState extends ConsumerState<RiverpodAuditPage> {
  // Which tab is selected is ephemeral UI state owned by this one widget, so
  // it stays in setState. Not everything needs a provider.
  late String _aisle = widget.aisles.first;

  @override
  Widget build(BuildContext context) {
    final provider = auditControllerProvider(_aisle);
    final audit = ref.watch(provider);
    ref.read(traceProvider)(TraceLayer.ui, 'build ← ${_describe(audit)}');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AislePicker(
                aisles: widget.aisles,
                selected: _aisle,
                onSelected: (aisle) => setState(() => _aisle = aisle),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(provider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        // A refresh keeps the previous data (or error) and only raises
        // isLoading, so this bar is the only thing that changes on screen.
        SizedBox(
          height: 4,
          child: audit.isRefreshing ? const LinearProgressIndicator() : null,
        ),
        Expanded(
          // Order matters. Data first: a failed refresh is an AsyncError that
          // still carries the old list, and the list is worth keeping.
          child: switch (audit) {
            AsyncValue(:final value?) => AuditListView(
              entries: value,
              // Looked up at tap time: a refresh replaces the notifier, and a
              // tear-off captured during build would point at the old one.
              onRecord: (barcode, shelfPrice) => ref
                  .read(provider.notifier)
                  .recordShelfPrice(barcode, shelfPrice),
            ),
            AsyncValue(error: final Failure failure) => FailureView(
              failure: failure,
              onRetry: () => ref.invalidate(provider),
              retrying: audit.isLoading,
            ),
            // Not a Failure, so it is a bug: let the framework report it.
            AsyncValue(:final error?, :final stackTrace?) =>
              Error.throwWithStackTrace(error, stackTrace),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }

  static String _describe(AsyncValue<Object?> value) {
    final kind = switch (value) {
      AsyncData() => 'AsyncData',
      AsyncError() => 'AsyncError',
      AsyncLoading() => 'AsyncLoading',
    };
    return value.isLoading && value is! AsyncLoading
        ? '$kind (isLoading)'
        : kind;
  }
}
