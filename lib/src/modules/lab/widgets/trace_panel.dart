import 'package:flutter/material.dart';
import 'package:project_lab/src/core/theme/theme.dart';

import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/lab/providers/trace_log.dart';

/// Shows the events of a [TraceLog], newest at the bottom.
class TracePanel extends StatelessWidget {
  const TracePanel({super.key, required this.log});

  final TraceLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              Expanded(child: Text('Trace', style: theme.textTheme.titleSmall)),
              TextButton(onPressed: log.clear, child: const Text('Clear')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 10,
            children: [for (final layer in TraceLayer.values) _Legend(layer)],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListenableBuilder(
            listenable: log,
            builder: (context, _) {
              final events = log.events;
              if (events.isEmpty) {
                return const Center(child: Text('Interact with the demo.'));
              }
              // reverse pins the view to the newest event; shrinkWrap plus
              // the top alignment keeps a short log at the top of the pane.
              return Align(
                alignment: Alignment.topCenter,
                child: ListView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: events.length,
                  itemBuilder: (context, index) =>
                      _EventRow(events[events.length - 1 - index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.layer);

  final TraceLayer layer;

  @override
  Widget build(BuildContext context) {
    return Text(
      layer.name,
      style: TextStyle(
        color: LabColors.of(context).layer(layer),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.event);

  final TraceEvent event;

  @override
  Widget build(BuildContext context) {
    final seconds = (event.at.inMilliseconds / 1000).toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${seconds.padLeft(6)}s  ',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            TextSpan(
              text: event.message,
              style: TextStyle(color: LabColors.of(context).layer(event.layer)),
            ),
          ],
        ),
        style: const TextStyle(
          fontFamily: 'Consolas',
          fontFamilyFallback: ['monospace'],
          fontSize: 12.5,
        ),
      ),
    );
  }
}
