import 'package:flutter/material.dart';
import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_view_model.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository.dart';
import 'package:project_lab/src/modules/price_audit/widgets/aisle_picker.dart';
import 'package:project_lab/src/modules/price_audit/widgets/audit_list_view.dart';
import 'package:project_lab/src/widgets/failure_view.dart';

/// The page owns its view model: created in [State.initState], disposed in
/// [State.dispose]. The repository arrives from above (constructor
/// injection), so this file never names a concrete data class.
class PlainAuditPage extends StatefulWidget {
  const PlainAuditPage({
    super.key,
    required this.repository,
    required this.aisles,
    this.trace = noTrace,
  });

  final PriceAuditRepository repository;
  final List<String> aisles;
  final Trace trace;

  @override
  State<PlainAuditPage> createState() => _PlainAuditPageState();
}

class _PlainAuditPageState extends State<PlainAuditPage> {
  late final AuditViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuditViewModel(
      repository: widget.repository,
      aisle: widget.aisles.first,
      trace: widget.trace,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        widget.trace(TraceLayer.ui, 'build ← ${state.runtimeType}');
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: AislePicker(
                aisles: widget.aisles,
                selected: _viewModel.aisle,
                onSelected: _viewModel.selectAisle,
              ),
            ),
            Expanded(
              child: switch (state) {
                AuditLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                AuditFailed(:final failure) => FailureView(
                  failure: failure,
                  onRetry: _viewModel.load,
                ),
                AuditLoaded(:final entries) => AuditListView(
                  entries: entries,
                  onRecord: _viewModel.recordShelfPrice,
                ),
              },
            ),
          ],
        );
      },
    );
  }
}
