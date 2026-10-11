import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/core/theme/theme.dart';
import 'package:project_lab/src/lessons/dart/d03_future_vs_stream/playgrounds.dart';
import 'package:project_lab/src/lessons/dart/d03_future_vs_stream/quest.dart';
import 'package:project_lab/src/modules/lab/models/quest.dart';

/// Each playground can be won, and what it shows is what the real stream
/// did. Fake time: `pump(duration)` runs the playgrounds' timers.
void main() {
  late int goals;

  setUp(() => goals = 0);

  Future<void> pumpPlay(WidgetTester tester, Widget play) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(child: play)),
      ),
    );
  }

  Future<void> wait(WidgetTester tester, int milliseconds) =>
      tester.pump(Duration(milliseconds: milliseconds));

  void onGoal() => goals++;

  testWidgets('future vs stream: one pizza, many plates', (tester) async {
    await pumpPlay(tester, FutureVsStreamPlay(onGoal: onGoal));

    await tester.tap(find.text('🍕 Order a pizza'));
    await wait(tester, 1000);
    expect(find.textContaining('Delivered'), findsOneWidget);
    expect(goals, 0);

    await tester.tap(find.text('🍣 Open the belt'));
    await wait(tester, 2200);
    expect(find.textContaining('3 plates so far'), findsOneWidget);
    expect(goals, greaterThan(0));

    await tester.tap(find.text('✋ Stop the belt'));
    await wait(tester, 2000);
    expect(find.textContaining('3 plates so far'), findsOneWidget);
  });

  testWidgets('lazy: nothing is made before listen', (tester) async {
    await pumpPlay(tester, LazyPlay(onGoal: onGoal));

    await tester.tap(find.text('🛠️ Create the stream'));
    await wait(tester, 3000);
    expect(find.textContaining('made 0 · nobody listening'), findsOneWidget);

    await tester.tap(find.text('👂 Listen'));
    await wait(tester, 1300);
    expect(find.text('💧 made 2 · 🪴 received 2'), findsOneWidget);
    expect(goals, greaterThan(0));
  });

  testWidgets('pause: the bucket fills, resume pours it out', (tester) async {
    await pumpPlay(tester, PausePlay(onGoal: onGoal));

    await tester.tap(find.text('▶️ Start'));
    await wait(tester, 1100);
    await tester.tap(find.text('⏸️ Pause'));
    await wait(tester, 1600);
    expect(find.textContaining('received 2 · 🪣 waiting 3'), findsOneWidget);
    expect(find.text('🪣 3'), findsOneWidget);

    await tester.tap(find.text('▶️ Resume'));
    await wait(tester, 50);
    expect(find.textContaining('received 5 · 🪣 waiting 0'), findsOneWidget);
    expect(goals, 1);
  });

  testWidgets('pausing too briefly does not pass', (tester) async {
    await pumpPlay(tester, PausePlay(onGoal: onGoal));

    await tester.tap(find.text('▶️ Start'));
    await wait(tester, 600);
    await tester.tap(find.text('⏸️ Pause'));
    await tester.pump();
    await tester.tap(find.text('▶️ Resume'));
    await wait(tester, 50);

    expect(goals, 0);
  });

  testWidgets('cancel: onCancel stops the producer', (tester) async {
    await pumpPlay(tester, CancelPlay(onGoal: onGoal));

    await tester.tap(find.text('👂 Listen'));
    await wait(tester, 700);
    expect(find.text('🏭'), findsOneWidget);

    await tester.tap(find.text('✂️ Cancel'));
    await wait(tester, 50);
    expect(find.text('💤'), findsOneWidget);
    expect(find.textContaining('onCancel ran'), findsOneWidget);
    expect(goals, 1);

    await wait(tester, 2000);
    expect(find.textContaining('onCancel ran'), findsOneWidget);
  });

  testWidgets('broadcast: the second TV listen throws, radios share', (
    tester,
  ) async {
    await pumpPlay(tester, BroadcastPlay(onGoal: onGoal));

    await tester.tap(find.text('👀 Listen'));
    await wait(tester, 50);
    await tester.tap(find.text('👀 Listen again'));
    await wait(tester, 50);
    expect(
      find.text('💥 StateError: Stream has already been listened to.'),
      findsOneWidget,
    );

    await tester.tap(find.text('➕ Add a listener'));
    await wait(tester, 1000);
    await tester.tap(find.text('➕ Add a listener'));
    await wait(tester, 1000);

    // The first radio heard a goal the second one missed.
    expect(find.text('📻 #1 heard 2'), findsOneWidget);
    expect(find.text('📻 #2 heard 1'), findsOneWidget);
    expect(goals, 1);
  });

  testWidgets('errors: listen carries on, await for stops', (tester) async {
    await pumpPlay(tester, ErrorsPlay(onGoal: onGoal));

    await tester.tap(find.text('▶️ Run').first);
    await tester.tap(find.text('▶️ Run').last);
    await wait(tester, 2000);

    // listen saw the 3 after the error; await for did not.
    expect(find.text('✅ 3️⃣'), findsOneWidget);
    expect(find.text('❌ 💣'), findsOneWidget);
    expect(find.text('🏁 done'), findsOneWidget);
    expect(find.text('💥 💣 thrown: the loop stopped'), findsOneWidget);
    expect(goals, 1);
  });

  test('the quest alternates play and quiz, and every quiz answer exists', () {
    expect(streamQuest.steps.whereType<Play>(), hasLength(6));
    expect(streamQuest.steps.whereType<Quiz>(), hasLength(6));
    for (final quiz in streamQuest.steps.whereType<Quiz>()) {
      expect(quiz.answer, inInclusiveRange(0, quiz.choices.length - 1));
    }
  });
}
