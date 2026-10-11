import 'package:flutter/material.dart';
import 'package:project_lab/src/core/theme/theme_mode_scope.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';
import 'package:project_lab/src/modules/lab/providers/quest_progress.dart';
import 'package:project_lab/src/modules/lab/providers/trace_log.dart';
import 'package:project_lab/src/modules/lab/widgets/lesson_brief.dart';
import 'package:project_lab/src/modules/lab/widgets/quest_view.dart';
import 'package:project_lab/src/modules/lab/widgets/trace_panel.dart';

/// A lesson with a quest opens on the game. The lab view (brief, demo and
/// trace side by side on a wide window, one at a time on a narrow one) is a
/// tap away, and is the only view for a lesson without a quest.
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
  // Built on first use (so the game view runs no demo in the background),
  // and keyed so the running demo survives a resize that moves it between
  // the wide and the narrow layout.
  late final Widget _demo = KeyedSubtree(
    key: GlobalKey(),
    child: widget.lesson.demo(_trace),
  );
  // Lives as long as the page, so switching views does not lose the score.
  late final QuestProgress? _quest = switch (widget.lesson.quest) {
    final quest? => QuestProgress(quest),
    null => null,
  };
  late bool _gameView = _quest != null;
  _Pane _pane = _Pane.demo;

  @override
  void dispose() {
    _quest?.dispose();
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final quest = _quest;

    return Scaffold(
      appBar: AppBar(
        title: Text('${lesson.id} · ${lesson.title}'),
        actions: [
          if (quest != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                onPressed: () => setState(() => _gameView = !_gameView),
                child: Text(_gameView ? '🔬 Open lab' : '🎮 Back to game'),
              ),
            ),
          const ThemeModeButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: quest != null && _gameView
          ? QuestView(progress: quest)
          : _labView(lesson),
    );
  }

  Widget _labView(Lesson lesson) {
    final brief = LessonBrief(lesson: lesson);
    final trace = TracePanel(log: _trace);
    return LayoutBuilder(
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
    );
  }
}
