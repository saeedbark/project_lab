import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/core/theme/theme.dart';
import 'package:project_lab/src/modules/lab/models/quest.dart';
import 'package:project_lab/src/modules/lab/providers/quest_progress.dart';
import 'package:project_lab/src/modules/lab/widgets/quest_view.dart';

final _quest = Quest(
  badge: '🧪 Tester',
  steps: [
    const Quiz(
      emoji: '❓',
      title: 'Pick the second',
      question: 'Which one?',
      choices: ['First', 'Second'],
      answer: 1,
      why: 'The second is right.',
    ),
    Play(
      emoji: '🎮',
      title: 'Press it',
      intro: 'A button that passes the level.',
      goal: 'Press the button.',
      builder: (onGoal) =>
          ElevatedButton(onPressed: onGoal, child: const Text('Win')),
    ),
  ],
);

void main() {
  late QuestProgress progress;

  setUp(() => progress = QuestProgress(_quest));
  tearDown(() => progress.dispose());

  Future<void> pumpQuest(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: QuestView(progress: progress)),
      ),
    );
  }

  /// Lets the switch, the bar and the celebration finish.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

  testWidgets('plays from 0% to the trophy', (tester) async {
    await pumpQuest(tester);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Level 1 of 2'), findsOneWidget);

    await tester.tap(find.text('First'));
    await settle(tester);
    expect(find.text('❌'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.textContaining('The second is right'), findsNothing);

    await tester.tap(find.text('Second'));
    await settle(tester);
    expect(find.text('💡 The second is right.'), findsOneWidget);
    expect(find.text('🎉 Level cleared! +10 XP'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Press it'), findsOneWidget);
    expect(find.text('🎯'), findsOneWidget);

    await tester.tap(find.text('Win'));
    await settle(tester);
    expect(find.text('✅'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Quest complete!'), findsOneWidget);
    expect(find.text('Badge earned: 🧪 Tester'), findsOneWidget);
    expect(find.text('⚡ 30 XP'), findsWidgets);

    await tester.tap(find.text('Play again'));
    await settle(tester);
    expect(find.text('Level 1 of 2'), findsOneWidget);
  });

  testWidgets('a right first answer earns the bonus and a star', (
    tester,
  ) async {
    await pumpQuest(tester);

    await tester.tap(find.text('Second'));
    await settle(tester);

    expect(find.text('🎉 Level cleared! +15 XP'), findsOneWidget);
    expect(find.text('⭐ 1/1'), findsOneWidget);
  });
}
