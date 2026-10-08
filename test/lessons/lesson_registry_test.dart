import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/app.dart';
import 'package:project_lab/src/lessons/lesson_registry.dart';

void main() {
  test('lesson ids are unique', () {
    final ids = [for (final lesson in lessons) lesson.id];

    expect(ids.toSet(), hasLength(ids.length));
  });

  // A reading path that points at a renamed file wastes a session.
  test('every file a lesson points at exists', () {
    for (final lesson in lessons) {
      final paths = [
        lesson.notesPath,
        for (final step in lesson.readingPath) step.path,
        for (final step in lesson.testPath) step.path,
      ];
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '${lesson.id}: $path');
      }
    }
  });

  testWidgets('the home page lists every lesson and opens one', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(LabApp(lessons: lessons));
    for (final lesson in lessons) {
      expect(find.textContaining(lesson.title), findsOneWidget);
    }

    await tester.tap(find.textContaining(lessons.first.title));
    await tester.pumpAndSettle();
    expect(find.text('Trace'), findsOneWidget);
    expect(find.text('Fresh milk 1L'), findsOneWidget);
  });
}
