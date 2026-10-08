import 'package:flutter/material.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';

/// The plan for one work window: three 50-minute periods, each ending in
/// something concrete.
class LessonBrief extends StatelessWidget {
  const LessonBrief({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(lesson.goal, style: text.titleMedium),
          const SizedBox(height: 8),
          Text('Career-OS: ${lesson.careerOs}', style: text.bodySmall),
          Text('Replaces: ${lesson.replaces}', style: text.bodySmall),
          _Period(
            number: 1,
            title: 'Run it and read it',
            steps: [
              _Step(
                'Run the demo · 10 min',
                children: [for (final item in lesson.watchFor) _Bullet(item)],
              ),
              _Step(
                'Read the code in this order · 40 min',
                children: [
                  for (final (index, step) in lesson.readingPath.indexed)
                    _FileStep(index: index + 1, step: step),
                ],
              ),
            ],
          ),
          _Period(
            number: 2,
            title: 'Question it',
            steps: [
              _Step(
                'Read the decisions · 20 min',
                children: [_Path(lesson.notesPath)],
              ),
              _Step(
                'Read the tests · 15 min',
                children: [
                  for (final (index, step) in lesson.testPath.indexed)
                    _FileStep(index: index + 1, step: step),
                ],
              ),
              const _Step(
                'Ask Claude "why not…?" · 15 min',
                children: [
                  _Bullet(
                    'Pick two decisions from the notes and ask what breaks '
                    'if each is done the other way.',
                  ),
                ],
              ),
            ],
          ),
          _Period(
            number: 3,
            title: 'Say it, then go to the source',
            steps: [
              _Step(
                'Explain aloud, in English · 15 min',
                children: [for (final item in lesson.explain) _Bullet(item)],
              ),
              _Step(
                'Read the primary source · 30 min',
                children: [
                  for (final source in lesson.sources)
                    _Bullet('${source.title}\n${source.url}'),
                ],
              ),
              const _Step(
                'Close · 5 min',
                children: [
                  _Bullet(
                    'Write one line: what is now clear, and what is still '
                    'not. Tick the Career-OS task.',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Period extends StatelessWidget {
  const _Period({
    required this.number,
    required this.title,
    required this.steps,
  });

  final int number;
  final String title;
  final List<Widget> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Period $number · 50 min · $title',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          ...steps,
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.title, {required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _FileStep extends StatelessWidget {
  const _FileStep({required this.index, required this.step});

  final int index;
  final ReadingStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Path('$index. ${step.path}'),
          Text(step.lookFor, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Path extends StatelessWidget {
  const _Path(this.path);

  final String path;

  @override
  Widget build(BuildContext context) {
    return Text(
      path,
      style: const TextStyle(
        fontFamily: 'Consolas',
        fontFamilyFallback: ['monospace'],
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
