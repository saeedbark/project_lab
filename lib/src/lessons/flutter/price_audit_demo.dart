import 'package:flutter/material.dart';
import 'package:project_lab/src/modules/lab/providers/trace_log.dart';
import 'package:project_lab/src/modules/price_audit/services/fake_price_api.dart';

/// The frame both price-audit lessons run in: one fake server whose network
/// condition can be changed while the screen under study is live.
class PriceAuditDemo extends StatefulWidget {
  const PriceAuditDemo({super.key, required this.trace, required this.builder});

  final TraceLog trace;

  /// Builds the screen under study on top of the fake server. Called once.
  final Widget Function(FakePriceApi api) builder;

  @override
  State<PriceAuditDemo> createState() => _PriceAuditDemoState();
}

class _PriceAuditDemoState extends State<PriceAuditDemo> {
  late final _api = FakePriceApi(trace: widget.trace.add);
  late final _screen = widget.builder(_api);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text('Network'),
              SegmentedButton<NetworkCondition>(
                segments: const [
                  ButtonSegment(
                    value: NetworkCondition.normal,
                    label: Text('Normal'),
                  ),
                  ButtonSegment(
                    value: NetworkCondition.slow,
                    label: Text('Slow'),
                  ),
                  ButtonSegment(
                    value: NetworkCondition.offline,
                    label: Text('Offline'),
                  ),
                  ButtonSegment(
                    value: NetworkCondition.serverError,
                    label: Text('503'),
                  ),
                ],
                selected: {_api.condition},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _api.condition = selection.single),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(child: _screen),
      ],
    );
  }
}
