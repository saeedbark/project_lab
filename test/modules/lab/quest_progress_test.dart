import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/modules/lab/models/quest.dart';
import 'package:project_lab/src/modules/lab/providers/quest_progress.dart';

Widget _noPlayground(VoidCallback onGoal) => const SizedBox();

final _quest = Quest(
  badge: '🧪 Tester',
  steps: [
    const Quiz(
      emoji: '❓',
      title: 'Pick B',
      question: 'Which?',
      choices: ['A', 'B'],
      answer: 1,
      why: 'Because.',
    ),
    Play(
      emoji: '🎮',
      title: 'Do it',
      intro: 'Intro',
      goal: 'Goal',
      builder: _noPlayground,
    ),
  ],
);

void main() {
  late QuestProgress progress;

  setUp(() => progress = QuestProgress(_quest));
  tearDown(() => progress.dispose());

  test('starts at 0% on the first step', () {
    expect(progress.index, 0);
    expect(progress.percent, 0);
    expect(progress.current, isA<Quiz>());
  });

  test('a right first answer clears the step with the bonus and a star', () {
    expect(progress.answer(1), isTrue);

    expect(progress.cleared, isTrue);
    expect(progress.xp, 10 + QuestProgress.firstTryBonus);
    expect(progress.stars, 1);
    expect(progress.percent, 0.5);
  });

  test('a wrong answer can be retried, but costs the star and bonus', () {
    expect(progress.answer(0), isFalse);
    expect(progress.cleared, isFalse);

    expect(progress.answer(1), isTrue);
    expect(progress.xp, 10);
    expect(progress.stars, 0);
    expect(progress.picked, {0, 1});
  });

  test('next does nothing until the step is cleared', () {
    progress.next();
    expect(progress.index, 0);

    progress
      ..answer(1)
      ..next();
    expect(progress.index, 1);
    expect(progress.cleared, isFalse);
    expect(progress.picked, isEmpty);
  });

  test('a play step clears once, however often its goal is reached', () {
    progress
      ..answer(1)
      ..next()
      ..reachGoal()
      ..reachGoal();

    expect(progress.xp, 15 + 20);
    expect(progress.percent, 1);
  });

  test('reachGoal does nothing on a quiz', () {
    progress.reachGoal();

    expect(progress.cleared, isFalse);
  });

  test('after the last step the quest is finished; restart resets it', () {
    progress
      ..answer(1)
      ..next()
      ..reachGoal()
      ..next();
    expect(progress.finished, isTrue);
    expect(progress.current, isNull);

    progress.restart();
    expect(progress.index, 0);
    expect(progress.xp, 0);
    expect(progress.stars, 0);
  });
}
