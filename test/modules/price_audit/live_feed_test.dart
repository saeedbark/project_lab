import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/modules/price_audit/services/fake_price_api.dart';
import 'package:project_lab/src/modules/price_audit/services/price_api.dart';

typedef Rows = List<Map<String, Object?>>;

/// The Stream API, one behaviour per test, on the feed the app really uses.
/// `pumpEventQueue()` lets every pending microtask and zero-length timer run,
/// so "after the await" means "after the stream has done what it will do".
void main() {
  late FakePriceApi api;
  late List<String> trace;

  setUp(() {
    trace = [];
    api = FakePriceApi(
      trace: (_, message) => trace.add(message),
      latency: Duration.zero,
      repriceEvery: null,
    );
  });

  String price(Rows rows, String name) =>
      rows.firstWhere((row) => row['name'] == name)['system_price']! as String;

  group('a Future answers once, a Stream keeps answering', () {
    test('fetchAisle completes with one list and is finished', () async {
      final rows = await api.fetchAisle('Dairy');

      expect(rows, hasLength(4));
    });

    test(
      'watchAisle sends the aisle now, then again on every change',
      () async {
        final snapshots = <Rows>[];
        final subscription = api.watchAisle('Dairy').listen(snapshots.add);
        await pumpEventQueue();

        api.repriceNext(); // Fresh milk, Dairy
        await pumpEventQueue();
        api.repriceNext(); // Yogurt, Dairy
        await pumpEventQueue();

        expect(snapshots, hasLength(3));
        expect(price(snapshots[0], 'Fresh milk 1L'), '12.50');
        expect(price(snapshots[1], 'Fresh milk 1L'), '13.00');
        expect(price(snapshots[2], 'Yogurt 500g'), '8.50');
        await subscription.cancel();
      },
    );

    test('a change in another aisle sends nothing', () async {
      final snapshots = <Rows>[];
      final subscription = api.watchAisle('Drinks').listen(snapshots.add);
      await pumpEventQueue();

      api.repriceNext(); // Fresh milk: Dairy, not Drinks
      await pumpEventQueue();

      expect(snapshots, hasLength(1));
      await subscription.cancel();
    });
  });

  group('lazy: nothing happens until listen', () {
    test('creating the stream opens no connection', () async {
      final feed = api.watchAisle('Dairy');
      await pumpEventQueue();

      expect(trace, isEmpty);
      expect(api.hasLiveClients, isFalse);

      final subscription = feed.listen((_) {});
      await pumpEventQueue();

      expect(trace.first, startsWith('WS /aisles/Dairy/live'));
      expect(api.hasLiveClients, isTrue);
      await subscription.cancel();
    });
  });

  group('single-subscription', () {
    test('a second listen on the same feed throws', () async {
      final feed = api.watchAisle('Dairy');
      final subscription = feed.listen((_) {});

      expect(() => feed.listen((_) {}), throwsStateError);
      await subscription.cancel();
    });

    // The tempting fix for the StateError above, and why the app does not
    // use it: the socket outlives every widget that wanted it.
    test('asBroadcastStream keeps the feed open after the last listener '
        'leaves', () async {
      final shared = api.watchAisle('Dairy').asBroadcastStream();
      final first = shared.listen((_) {});
      final second = shared.listen((_) {});
      await pumpEventQueue();

      await first.cancel();
      await second.cancel();

      expect(api.hasLiveClients, isTrue);
    });
  });

  group('cancel', () {
    test('closes the connection at once, even if the aisle is quiet', () async {
      final subscription = api.watchAisle('Dairy').listen((_) {});
      await pumpEventQueue();
      expect(api.hasLiveClients, isTrue);

      await subscription.cancel();

      expect(api.hasLiveClients, isFalse);
      expect(trace, contains('WS /aisles/Dairy/live closed by the client'));
    });

    test('during the handshake, the feed never subscribes', () async {
      final slowApi = FakePriceApi(
        latency: const Duration(milliseconds: 20),
        repriceEvery: null,
      );
      final subscription = slowApi.watchAisle('Dairy').listen((_) {});

      await subscription.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(slowApi.hasLiveClients, isFalse);
    });

    test('await for: break cancels the subscription', () async {
      await for (final rows in api.watchAisle('Dairy')) {
        expect(rows, hasLength(4));
        break;
      }

      expect(api.hasLiveClients, isFalse);
    });
  });

  group('pause', () {
    test('await for pauses the feed while the loop body is busy', () async {
      await for (final _ in api.watchAisle('Dairy')) {
        // An event arrives while this body is still running. await for does
        // not queue it in the loop: it pauses the subscription, and the
        // feed buffers it. That is backpressure, for free.
        api.repriceNext();
        await pumpEventQueue();
        expect(
          trace,
          contains('WS /aisles/Dairy/live paused: snapshots are buffered'),
        );
        break;
      }
    });

    test('a paused feed buffers, and resume delivers everything', () async {
      final snapshots = <Rows>[];
      final subscription = api.watchAisle('Dairy').listen(snapshots.add);
      await pumpEventQueue();

      subscription.pause();
      api
        ..repriceNext()
        ..repriceNext();
      await pumpEventQueue();
      expect(snapshots, hasLength(1));

      subscription.resume();
      await pumpEventQueue();
      expect(snapshots, hasLength(3));
      await subscription.cancel();
    });
  });

  group('broadcast: the server bus', () {
    test(
      'many feeds at once, and a late one only gets what is current',
      () async {
        final early = <Rows>[];
        final first = api.watchAisle('Dairy').listen(early.add);
        await pumpEventQueue();
        api.repriceNext(); // only `first` hears this event
        await pumpEventQueue();

        final late = <Rows>[];
        final second = api.watchAisle('Dairy').listen(late.add);
        await pumpEventQueue();

        expect(early, hasLength(2));
        // No replay of the event: one snapshot that already includes it.
        expect(late, hasLength(1));
        expect(price(late.single, 'Fresh milk 1L'), '13.00');
        await first.cancel();
        await second.cancel();
      },
    );

    test('repricing runs only while somebody listens', () async {
      final timed = FakePriceApi(
        trace: (_, message) => trace.add(message),
        latency: Duration.zero,
        repriceEvery: const Duration(hours: 1),
      );
      final first = timed.watchAisle('Dairy').listen((_) {});
      final second = timed.watchAisle('Bakery').listen((_) {});
      await pumpEventQueue();

      await first.cancel();
      expect(trace, isNot(contains('no live clients: repricing stopped')));
      await second.cancel();

      expect(trace, contains('first live client: repricing started'));
      expect(trace, contains('no live clients: repricing stopped'));
    });
  });

  group('errors', () {
    test('a dropped connection is one error event, then done', () async {
      final events = <Object>[];
      api
          .watchAisle('Dairy')
          .listen(
            events.add,
            onError: events.add,
            onDone: () => events.add('done'),
          );
      await pumpEventQueue();

      api.condition = NetworkCondition.offline;
      api.repriceNext();
      await pumpEventQueue();

      expect(events, [isA<Rows>(), isA<ConnectionException>(), 'done']);
      expect(api.hasLiveClients, isFalse);
      // The server ended it; the client cancelled nothing.
      expect(
        trace,
        isNot(contains('WS /aisles/Dairy/live closed by the client')),
      );
    });

    test('with listen, an error event alone does not end a stream', () async {
      // The feed closes itself after an error; the Stream API does not
      // require it. A controller that keeps going keeps delivering.
      final controller = StreamController<int>();
      final events = <Object>[];
      controller.stream.listen(events.add, onError: events.add);

      controller
        ..add(1)
        ..addError('blip')
        ..add(2);
      await pumpEventQueue();

      expect(events, [1, 'blip', 2]);
      await controller.close();
    });

    test('with await for, an error event is thrown out of the loop', () async {
      final controller = StreamController<int>();
      final received = <int>[];
      controller
        ..add(1)
        ..addError('blip')
        ..add(2);

      await expectLater(() async {
        await for (final value in controller.stream) {
          received.add(value);
        }
      }(), throwsA('blip'));

      expect(received, [1]);
      // Leaving the loop cancelled the subscription: 2 is never read.
      expect(controller.hasListener, isFalse);
    });
  });

  // The design decision in fake_price_api.dart, pinned on Dart 3.13. If this
  // test ever fails, the SDK changed and the async* version became viable.
  group('why the feed is not an async* generator', () {
    late StreamController<String> bus;

    setUp(() => bus = StreamController<String>.broadcast());
    tearDown(() => bus.close());

    Stream<String> asyncStarFeed() async* {
      await for (final changed in bus.stream) {
        yield changed;
      }
    }

    test('cancel waits until the source emits again', () async {
      final subscription = asyncStarFeed().listen((_) {});
      await pumpEventQueue();
      var cancelled = false;

      unawaited(subscription.cancel().then((_) => cancelled = true));
      await pumpEventQueue();

      // The body is parked inside `await for`; it only sees the cancel at
      // its next `yield`. Meanwhile the source is still subscribed.
      expect(cancelled, isFalse);
      expect(bus.hasListener, isTrue);

      bus.add('Dairy');
      await pumpEventQueue();

      expect(cancelled, isTrue);
      expect(bus.hasListener, isFalse);
    });
  });
}
