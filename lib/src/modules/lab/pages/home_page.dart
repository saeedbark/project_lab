import 'package:flutter/material.dart';
import 'package:project_lab/src/core/theme/theme.dart';
import 'package:project_lab/src/core/theme/theme_mode_scope.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';
import 'package:project_lab/src/modules/lab/pages/lesson_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.lessons});

  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Lab'),
        actions: const [ThemeModeButton(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Banner(),
          for (final track in Track.values)
            if (lessons.where((l) => l.track == track).toList()
                case final inTrack when inTrack.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(
                  track.label,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final (index, lesson) in inTrack.indexed)
                _LessonCard(lesson: lesson, colorIndex: index),
            ],
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final game = LabColors.of(context).game;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [for (final c in game.take(4)) c.withValues(alpha: 0.25)],
        ),
      ),
      child: Row(
        children: [
          const Text('🧪', style: TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learn by playing',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'One lesson per work window. Clear every level to reach '
                  '100%, then open the lab to read the real code.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.colorIndex});

  final Lesson lesson;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = LabColors.of(context).game[colorIndex % 5];
    final quest = lesson.quest;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: quest != null
              ? accent.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => LessonPage(lesson: lesson),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  lesson.id,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.id} · ${lesson.title}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(lesson.goal, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      lesson.careerOs,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (quest != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '🎮 ${quest.steps.length}-level game · '
                        'earn ${quest.badge}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                quest != null ? Icons.play_circle_fill : Icons.chevron_right,
                color: quest != null ? accent : theme.colorScheme.outline,
                size: quest != null ? 36 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
