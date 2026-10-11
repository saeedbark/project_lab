import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_lab/src/lessons/dart/d03_future_vs_stream/quest.dart';
import 'package:project_lab/src/lessons/flutter/price_audit_demo.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';
import 'package:project_lab/src/modules/price_audit/pages/live_audit_page.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';
import 'package:project_lab/src/modules/price_audit/services/fake_price_api.dart';

const _module = 'lib/src/modules/price_audit';
const _tests = 'test/modules/price_audit';

final d03FutureVsStream = Lesson(
  id: 'd03',
  track: Track.dart,
  title: 'Future vs Stream',
  goal:
      'I can say when an API should return a Stream instead of a Future, '
      'and explain what listen, cancel, pause, broadcast and await for do '
      'to a live feed.',
  careerOs:
      'Week 1 · w1t2 (the async guide), w1t6 (5-minute recording), '
      'w1t7 (async interview questions)',
  replaces:
      'dart.dev "Asynchronous programming: Streams", the Streams half of '
      'the async tutorial, and "Dart Streams — Flutter in Focus".',
  watchFor: [
    'Open the demo and find "WS /aisles/Dairy/live" in the trace. Nothing '
        'connected until the page listened. That is a lazy stream.',
    'Wait. Every 5 s head office reprices a product. A Dairy change reaches '
        'the list without any request. A Bakery change does not, because '
        'the Dairy feed filters by aisle.',
    'Record a shelf price. The list does not change when the PUT returns. '
        'It changes when the server\'s echo arrives on the feed.',
    'Switch to Bakery. Read the order: subscription paused, then disposed, '
        'then "closed by the client". Leaving an aisle closes its socket.',
    'Tap "Open another screen", wait 10 s, come back. The feed was paused '
        'and buffered snapshots, and they all arrive at once on resume.',
    'Go Offline and wait for the next reprice. The feed drops, the list '
        'stays, and a banner offers Reconnect. A failed stream is over.',
  ],
  readingPath: [
    (
      path: '$_module/services/price_api.dart',
      lookFor:
          'Two methods return Futures, one returns a Stream. The doc '
          'comment on watchAisle says why.',
    ),
    (
      path: '$_module/services/fake_price_api.dart',
      lookFor:
          'watchAisle: a single-subscription StreamController, its four '
          'callbacks, and the broadcast _changes bus it listens to. Note '
          'why it is not an async* generator.',
    ),
    (
      path: '$_module/services/price_audit_repository_impl.dart',
      lookFor:
          'loadAisle beside watchAisle: the same mapping, written as await '
          'for a Future and as a map/handleError pipeline for a Stream.',
    ),
    (
      path: '$_module/providers/audit_providers.dart',
      lookFor:
          'liveAisleProvider at the bottom: no notifier, no listen call. '
          'Compare it with AuditController.',
    ),
    (
      path: '$_module/pages/live_audit_page.dart',
      lookFor:
          'The switch, the banner for an error that arrives after data, '
          'and why Reconnect is invalidate.',
    ),
  ],
  testPath: [
    (
      path: '$_tests/live_feed_test.dart',
      lookFor:
          'Laziness, single subscription, cancel, pause, broadcast and await '
          'for, each pinned on the real feed. The last group is the async* '
          'trap that decided the design.',
    ),
    (
      path: '$_tests/price_audit_repository_impl_test.dart',
      lookFor: 'The "watchAisle" group: error events leave as Failures.',
    ),
    (
      path: '$_tests/live_audit_page_test.dart',
      lookFor:
          'Updates without a request, the Reconnect banner, and a covering '
          'route pausing the feed.',
    ),
  ],
  explain: [
    'Future versus Stream in one sentence each. When would you return a '
        'Stream from a repository, and when a Future?',
    'Single-subscription versus broadcast: which one is the feed, which '
        'one is the bus, and what goes wrong with the other choice?',
    'What does cancelling a subscription do here, all the way down?',
    'await for versus listen: why does the page never use await for?',
    'An error event arrives after three snapshots. What does the user see, '
        'and why is Reconnect a new subscription?',
  ],
  sources: [
    (
      title: 'dart.dev: Asynchronous programming: Streams',
      url: 'https://dart.dev/libraries/async/using-streams',
    ),
    (
      title: 'dart.dev: Creating streams in Dart',
      url: 'https://dart.dev/libraries/async/creating-streams',
    ),
    (
      title: 'Dart Streams — Flutter in Focus (video)',
      url: 'https://www.youtube.com/watch?v=nQBpOIHE4eE',
    ),
  ],
  notesPath: 'lib/src/lessons/dart/d03_future_vs_stream/NOTES.md',
  quest: streamQuest,
  demo: (trace) => PriceAuditDemo(
    trace: trace,
    builder: (api) => ProviderScope(
      overrides: [
        priceApiProvider.overrideWithValue(api),
        traceProvider.overrideWithValue(trace.add),
      ],
      child: const Column(
        children: [
          _CoverButton(),
          Expanded(child: LiveAuditPage(aisles: FakePriceApi.aisles)),
        ],
      ),
    ),
  ),
);

/// Pushes a full-screen route over the lesson. The audit page stays mounted
/// but hidden, which is how a real app's screen ends up paused.
class _CoverButton extends StatelessWidget {
  const _CoverButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton.icon(
        icon: const Icon(Icons.layers_outlined),
        label: const Text('Open another screen'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Another screen')),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'The audit page is covered, so its feed is paused. '
                    'Wait a few seconds, then go back and read the trace.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
