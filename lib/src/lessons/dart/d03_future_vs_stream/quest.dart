import 'package:project_lab/src/lessons/dart/d03_future_vs_stream/playgrounds.dart';
import 'package:project_lab/src/modules/lab/models/quest.dart';

/// d03 as a game: six playgrounds on real streams, six quizzes between them.
final streamQuest = Quest(
  badge: '🌊 Stream Tamer',
  steps: [
    Play(
      emoji: '🍕',
      title: 'One value or many?',
      intro:
          'A Future is a pizza order: one value arrives, then it is done. A '
          'Stream is a sushi belt: values keep coming until you stop it.',
      goal: 'Get your pizza, and eat 3 plates from the belt.',
      builder: (onGoal) => FutureVsStreamPlay(onGoal: onGoal),
    ),
    const Quiz(
      emoji: '⚽',
      title: 'Future or Stream?',
      question: 'Show the live score of a match while it is being played.',
      choices: ['Future', 'Stream'],
      answer: 1,
      why:
          'The score changes many times and you do not know when. Many values '
          'over time is a Stream.',
    ),
    const Quiz(
      emoji: '👤',
      title: 'Future or Stream?',
      question: 'Load the user\'s profile once when the screen opens.',
      choices: ['Future', 'Stream'],
      answer: 0,
      why:
          'One question, one answer. Even if you ask again on pull-to-refresh, '
          'each ask is one Future.',
    ),
    Play(
      emoji: '😴',
      title: 'Streams are lazy',
      intro:
          'Creating a stream is like writing a recipe. Nothing is cooked until '
          'someone listens.',
      goal:
          'Create the stream, wait, see "made 0", then listen and get 2 drops.',
      builder: (onGoal) => LazyPlay(onGoal: onGoal),
    ),
    const Quiz(
      emoji: '🧪',
      title: 'How many events?',
      question:
          'The producer starts in onListen. This code runs, and nothing else '
          'happens. How many events have been made?',
      code: 'final drops = makeDripStream();\n// nobody calls listen',
      choices: ['0', '1', 'It keeps making them forever'],
      answer: 0,
      why:
          'A single-subscription stream starts work when it gets its listener. '
          'No listen, no work. That is why a stream that is never listened to '
          'costs nothing.',
    ),
    Play(
      emoji: '⏸️',
      title: 'Pause fills the bucket',
      intro:
          'Pausing a subscription does not stop the producer. The stream holds '
          'the events in a buffer and pours them out on resume.',
      goal: 'Pause until 2 or more fruits wait in the bucket, then resume.',
      builder: (onGoal) => PausePlay(onGoal: onGoal),
    ),
    Play(
      emoji: '✂️',
      title: 'Cancel stops the factory',
      intro:
          'cancel() reaches the producer: its onCancel runs, and that is where '
          'timers stop and sockets close.',
      goal: 'Listen, receive a box, then cancel.',
      builder: (onGoal) => CancelPlay(onGoal: onGoal),
    ),
    const Quiz(
      emoji: '🚪',
      title: 'Forgot to cancel',
      question:
          'A screen listens to a stream in initState and never cancels. The '
          'user closes the screen. What happens?',
      choices: [
        'Dart cancels it when the screen closes',
        'The producer keeps working for nobody: a leak',
        'The app crashes at once',
      ],
      answer: 1,
      why:
          'Nothing cancels a subscription for you. Cancel it in dispose, or '
          'let StreamBuilder or Riverpod own it.',
    ),
    Play(
      emoji: '📻',
      title: 'One listener or many',
      intro:
          'A normal stream allows one listener, ever. A broadcast stream is a '
          'radio: many listeners, and nobody gets what was said before they '
          'tuned in.',
      goal: 'Make the TV throw its error, and tune in 2 radios.',
      builder: (onGoal) => BroadcastPlay(onGoal: onGoal),
    ),
    const Quiz(
      emoji: '📡',
      title: 'Late to the radio',
      question:
          'A broadcast stream sends "Goal!" while nobody listens. A listener '
          'joins one second later. Does it hear the goal?',
      choices: ['Yes, it is replayed', 'No, it is gone'],
      answer: 1,
      why:
          'Broadcast streams keep no history. That is why a live feed usually '
          'sends the current state first when you connect.',
    ),
    Play(
      emoji: '💣',
      title: 'Errors: listen vs await for',
      intro:
          'The same stream sends 1, 2, an error, then 3. Run it both ways and '
          'compare.',
      goal: 'Run both lanes to the end.',
      builder: (onGoal) => ErrorsPlay(onGoal: onGoal),
    ),
    const Quiz(
      emoji: '🧠',
      title: 'Final boss',
      question: 'Which sentence is true?',
      choices: [
        'With await for, an error event is thrown and the loop stops',
        'With listen, an error event always closes the stream',
        'A Future can deliver a second value if you await it again',
      ],
      answer: 0,
      why:
          'await for turns an error event into an exception and leaves the '
          'loop, which cancels the subscription. listen hands the error to '
          'onError and keeps going (you saw 3 arrive). A Future completes '
          'once.',
      xp: 20,
    ),
  ],
);
