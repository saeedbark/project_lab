import 'package:flutter/material.dart';
import 'package:project_lab/src/core/theme/theme_mode_scope.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';
import 'package:project_lab/src/modules/lab/providers/trace_log.dart';
import 'package:project_lab/src/modules/lab/widgets/lesson_brief.dart';
import 'package:project_lab/src/modules/lab/widgets/trace_panel.dart';

/// Brief, demo and trace side by side on a wide window; one at a time on a
/// narrow one.
class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

enum _Pane { brief, demo, trace }

class _LessonPageState extends State<LessonPage> {
  static const _wideBreakpoint = 1100.0;

  final _trace = TraceLog();
  // Built once, and keyed so the running demo survives a resize that moves
  // it between the wide and the narrow layout.
  late final Widget _demo = KeyedSubtree(
    key: GlobalKey(),
    child: widget.lesson.demo(_trace),
  );
  _Pane _pane = _Pane.demo;

  @override
  void dispose() {
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final brief = LessonBrief(lesson: lesson);
    final trace = TracePanel(log: _trace);

    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson.id} · ${lesson.title}'),
        actions: const [ThemeModeButton(), SizedBox(width: 8)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _wideBreakpoint) {
            return Row(
              children: [
                SizedBox(width: 360, child: brief),
                const VerticalDivider(width: 1),
                Expanded(child: _demo),
                const VerticalDivider(width: 1),
                SizedBox(width: 380, child: trace),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: SegmentedButton<_Pane>(
                  segments: const [
                    ButtonSegment(value: _Pane.brief, label: Text('Brief')),
                    ButtonSegment(value: _Pane.demo, label: Text('Demo')),
                    ButtonSegment(value: _Pane.trace, label: Text('Trace')),
                  ],
                  selected: {_pane},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      setState(() => _pane = selection.single),
                ),
              ),
              Expanded(
                // IndexedStack keeps the demo alive while another pane shows.
                child: IndexedStack(
                  index: _pane.index,
                  children: [brief, _demo, trace],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
