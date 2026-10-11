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

  testWidgets('a lesson with a quest opens on the game, and Lab is one tap '
      'away without losing the level', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final quested = lessons.firstWhere((lesson) => lesson.quest != null);

    await tester.pumpWidget(LabApp(lessons: lessons));
    await tester.tap(find.textContaining(quested.title).first);
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Trace'), findsNothing);

    // Level 1, played for real: a pizza and three plates.
    await tester.tap(find.text('🍕 Order a pizza'));
    await tester.tap(find.text('🍣 Open the belt'));
    for (var i = 0; i < 35; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(find.text('✋ Stop the belt'));
    await tester.tap(find.text('✋ Stop the belt'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('🔬 Open lab'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Trace'), findsOneWidget);

    await tester.tap(find.text('🎮 Back to game'));
    await tester.pumpAndSettle();
    expect(find.text('Level 2 of 12'), findsOneWidget);
  });
}
