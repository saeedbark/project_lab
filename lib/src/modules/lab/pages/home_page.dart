import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'One lesson per work window, in three 50-minute periods: run and '
            'read it, question it, explain it.',
            style: text.bodyLarge,
          ),
          for (final track in Track.values)
            if (lessons.where((l) => l.track == track).toList()
                case final inTrack when inTrack.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(track.label, style: text.titleMedium),
              ),
              for (final lesson in inTrack)
                Card(
                  child: ListTile(
                    title: Text('${lesson.id} · ${lesson.title}'),
                    subtitle: Text('${lesson.goal}\n${lesson.careerOs}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => LessonPage(lesson: lesson),
                      ),
                    ),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}
