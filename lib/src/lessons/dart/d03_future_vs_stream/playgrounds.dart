import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_lab/src/lessons/dart/d03_future_vs_stream/emoji_pipe.dart';

/// The d03 quest's playgrounds. Each one runs a real Future, StreamController
/// or subscription; the emoji only draw what the Dart objects did.
///
/// Every timer and subscription is cancelled in `dispose`, so leaving a level
/// mid-flight leaves nothing running.

const _sushi = ['🍣', '🍤', '🍙', '🥟'];

// ── Level: one value vs many ─────────────────────────────────────────────

class FutureVsStreamPlay extends StatefulWidget {
  const FutureVsStreamPlay({super.key, required this.onGoal});

  final VoidCallback onGoal;

  @override
  State<FutureVsStreamPlay> createState() => _FutureVsStreamPlayState();
}

class _FutureVsStreamPlayState extends State<FutureVsStreamPlay> {
  final _pipe = PipeController();
  Timer? _kitchen;
  String _pizza = 'Not ordered';
  bool _pizzaDone = false;
  StreamSubscription<String>? _belt;
  final _plates = <String>[];

  Future<void> _orderPizza() async {
    setState(() => _pizza = '⏳ Cooking…');
    // A Future: one value, later. Built on a Timer so dispose can stop it.
    final order = Completer<String>();
    _kitchen = Timer(
      const Duration(milliseconds: 900),
      () => order.complete('🍕'),
    );
    final pizza = await order.future;
    if (!mounted) return;
    setState(() {
      _pizza = '$pizza Delivered. The Future is complete: no more values.';
      _pizzaDone = true;
    });
    _check();
  }

  void _toggleBelt() {
    final belt = _belt;
    if (belt != null) {
      belt.cancel();
      setState(() => _belt = null);
      return;
    }
    // A Stream: values keep coming until we cancel.
    final stream = Stream.periodic(
      const Duration(milliseconds: 700),
      (i) => _sushi[i % _sushi.length],
    );
    setState(() {
      _belt = stream.listen((plate) {
        _pipe.launch(plate);
        setState(() => _plates.add(plate));
        _check();
      });
    });
  }

  void _check() {
    if (_pizzaDone && _plates.length >= 3) widget.onGoal();
  }

  @override
  void dispose() {
    _kitchen?.cancel();
    _belt?.cancel();
    _pipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stage(
          children: [
            Text('Future', style: Theme.of(context).textTheme.labelLarge),
            StatusText(_pizza),
            ActionRow(
              actions: [
                (
                  label: '🍕 Order a pizza',
                  onPressed: _pizza.startsWith('⏳') ? null : _orderPizza,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stage(
          children: [
            Text('Stream', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            EmojiPipe(
              controller: _pipe,
              producer: '👨‍🍳',
              listener: '😋',
              state: _belt == null ? PipeState.idle : PipeState.flowing,
            ),
            StatusText(
              _plates.isEmpty
                  ? 'Belt closed'
                  : '${_plates.length} ${_plates.length == 1 ? 'plate' : 'plates'} so far: ${_plates.takeLast(8).join()}',
            ),
            ActionRow(
              actions: [
                (
                  label: _belt == null ? '🍣 Open the belt' : '✋ Stop the belt',
                  onPressed: _toggleBelt,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── Level: lazy ──────────────────────────────────────────────────────────

/// A single-subscription controller whose producer starts in `onListen`:
/// until someone listens, nothing is made.
class LazyPlay extends StatefulWidget {
  const LazyPlay({super.key, required this.onGoal});

  final VoidCallback onGoal;

  @override
  State<LazyPlay> createState() => _LazyPlayState();
}

class _LazyPlayState extends State<LazyPlay> {
  final _pipe = PipeController();
  StreamController<String>? _controller;
  Timer? _tap;
  StreamSubscription<String>? _subscription;
  int _made = 0;
  int _received = 0;

  void _create() {
    setState(() {
      _controller = StreamController<String>(
        onListen: () {
          _tap = Timer.periodic(const Duration(milliseconds: 600), (_) {
            _made++;
            _controller!.add('💧');
          });
        },
        onCancel: () => _tap?.cancel(),
      );
    });
  }

  void _listen() {
    setState(() {
      _subscription = _controller!.stream.listen((drop) {
        _pipe.launch(drop);
        setState(() => _received++);
        if (_received >= 2) widget.onGoal();
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tap?.cancel();
    _pipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final created = _controller != null;
    final listening = _subscription != null;
    return Stage(
      children: [
        EmojiPipe(
          controller: _pipe,
          producer: listening ? '🚰' : '😴',
          listener: '🪴',
          state: listening ? PipeState.flowing : PipeState.idle,
        ),
        StatusText(switch ((created, listening)) {
          (false, _) => 'No stream yet',
          (true, false) => '😴 Stream created · made $_made · nobody listening',
          (true, true) => '💧 made $_made · 🪴 received $_received',
        }),
        ActionRow(
          actions: [
            (
              label: '🛠️ Create the stream',
              onPressed: created ? null : _create,
            ),
            (
              label: '👂 Listen',
              onPressed: created && !listening ? _listen : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Level: pause buffers ─────────────────────────────────────────────────

class PausePlay extends StatefulWidget {
  const PausePlay({super.key, required this.onGoal});

  final VoidCallback onGoal;

  @override
  State<PausePlay> createState() => _PausePlayState();
}

class _PausePlayState extends State<PausePlay> {
  static const _fruit = ['🍎', '🍌', '🍇', '🍓', '🍊'];

  final _pipe = PipeController();
  final _controller = StreamController<String>();
  Timer? _farm;
  StreamSubscription<String>? _subscription;
  int _made = 0;
  int _received = 0;

  /// Events the controller is holding for us: made but not yet received.
  int get _buffered => _made - _received;
  bool get _paused => _subscription?.isPaused ?? false;

  void _start() {
    // This producer does not check isPaused, so while we are paused it keeps
    // adding, and the controller keeps the events in its buffer.
    _farm = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _controller.add(_fruit[_made % _fruit.length]);
      setState(() => _made++);
    });
    setState(() {
      _subscription = _controller.stream.listen((fruit) {
        _pipe.launch(fruit);
        setState(() => _received++);
      });
    });
  }

  void _togglePause() {
    final subscription = _subscription!;
    if (subscription.isPaused) {
      final poured = _buffered;
      subscription.resume();
      if (poured >= 2) widget.onGoal();
    } else {
      subscription.pause();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _farm?.cancel();
    _subscription?.cancel();
    _pipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final started = _subscription != null;
    return Stage(
      children: [
        EmojiPipe(
          controller: _pipe,
          producer: '🧑‍🌾',
          listener: '🧺',
          state: !started
              ? PipeState.idle
              : _paused
              ? PipeState.paused
              : PipeState.flowing,
          buffered: _buffered,
        ),
        StatusText(
          started
              ? '🧑‍🌾 made $_made · 🧺 received $_received · 🪣 waiting $_buffered'
              : 'Press start',
        ),
        ActionRow(
          actions: [
            (label: '▶️ Start', onPressed: started ? null : _start),
            (
              label: _paused ? '▶️ Resume' : '⏸️ Pause',
              onPressed: started ? _togglePause : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Level: cancel ────────────────────────────────────────────────────────

class CancelPlay extends StatefulWidget {
  const CancelPlay({super.key, required this.onGoal});

  final VoidCallback onGoal;

  @override
  State<CancelPlay> createState() => _CancelPlayState();
}

class _CancelPlayState extends State<CancelPlay> {
  final _pipe = PipeController();
  late final StreamController<String> _controller = StreamController(
    onListen: () {
      _machine = Timer.periodic(const Duration(milliseconds: 600), (_) {
        _controller.add('📦');
      });
      setState(() => _factoryOn = true);
    },
    // The producer's side of cancel: this is where a socket would close.
    onCancel: () {
      _machine?.cancel();
      // dispose cancels too, and a disposing State must not setState.
      if (_leaving) return;
      setState(() {
        _factoryOn = false;
        _cancelHeard = true;
      });
      widget.onGoal();
    },
  );
  Timer? _machine;
  StreamSubscription<String>? _subscription;
  bool _factoryOn = false;
  bool _cancelHeard = false;
  bool _leaving = false;
  int _received = 0;

  void _listen() {
    setState(() {
      _subscription = _controller.stream.listen((box) {
        _pipe.launch(box);
        setState(() => _received++);
      });
    });
  }

  // The level passes in onCancel, when the producer has heard the cancel.
  void _cancel() => _subscription!.cancel();

  @override
  void dispose() {
    _leaving = true;
    _machine?.cancel();
    _subscription?.cancel();
    _pipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listening = _subscription != null;
    return Stage(
      children: [
        EmojiPipe(
          controller: _pipe,
          producer: _factoryOn ? '🏭' : '💤',
          listener: '📬',
          state: _cancelHeard
              ? PipeState.cut
              : listening
              ? PipeState.flowing
              : PipeState.idle,
        ),
        StatusText(switch ((listening, _cancelHeard)) {
          (false, _) => 'The factory is off until someone listens',
          (true, false) => '🏭 working · 📬 received $_received',
          (true, true) =>
            '✂️ cancel() → onCancel ran → 💤 the factory stopped its timer',
        }),
        ActionRow(
          actions: [
            (label: '👂 Listen', onPressed: listening ? null : _listen),
            (
              label: '✂️ Cancel',
              onPressed: listening && !_cancelHeard && _received >= 1
                  ? _cancel
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Level: one listener or many ──────────────────────────────────────────

class BroadcastPlay extends StatefulWidget {
  const BroadcastPlay({super.key, required this.onGoal});

  final VoidCallback onGoal;

  @override
  State<BroadcastPlay> createState() => _BroadcastPlayState();
}

class _BroadcastPlayState extends State<BroadcastPlay> {
  // Single-subscription: one listener, ever.
  final _tv = StreamController<String>();
  final _tvSubscriptions = <StreamSubscription<String>>[];
  String? _error;

  // Broadcast: any number of listeners; nothing is kept for latecomers.
  late final StreamController<String> _radio = StreamController.broadcast(
    onListen: () => _studio = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _radio.add('⚽ Goal ${++_goals}'),
    ),
    onCancel: () => _studio?.cancel(),
  );
  Timer? _studio;
  int _goals = 0;
  final _radioSubscriptions = <StreamSubscription<String>>[];
  final _heard = <int>[];

  void _watchTv() {
    try {
      _tvSubscriptions.add(_tv.stream.listen((_) {}));
      setState(() {});
    } on StateError catch (error) {
      setState(() => _error = error.message);
      _check();
    }
  }

  void _addRadio() {
    final index = _heard.length;
    _heard.add(0);
    _radioSubscriptions.add(
      _radio.stream.listen((_) => setState(() => _heard[index]++)),
    );
    setState(() {});
    _check();
  }

  void _check() {
    if (_error != null && _radioSubscriptions.length >= 2) widget.onGoal();
  }

  @override
  void dispose() {
    for (final subscription in [..._tvSubscriptions, ..._radioSubscriptions]) {
      subscription.cancel();
    }
    _studio?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stage(
          children: [
            Text(
              '📺 Single-subscription',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            StatusText(
              error != null
                  ? '💥 StateError: $error'
                  : '${_tvSubscriptions.length} watching',
            ),
            ActionRow(
              actions: [
                (
                  label: _tvSubscriptions.isEmpty
                      ? '👀 Listen'
                      : '👀 Listen again',
                  onPressed: error == null ? _watchTv : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stage(
          children: [
            Text(
              '📻 Broadcast · ${_goals == 0 ? 'off air' : 'goals so far: $_goals'}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (index, heard) in _heard.indexed)
                  Chip(label: Text('📻 #${index + 1} heard $heard')),
              ],
            ),
            const SizedBox(height: 8),
            ActionRow(
              actions: [
                (
                  label: '➕ Add a listener',
                  onPressed: _heard.length < 3 ? _addRadio : null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── Level: errors ────────────────────────────────────────────────────────

/// The same four events, read two ways. The source sends 1, 2, an error,
/// then 3.
class ErrorsPlay extends StatefulWidget {
  const ErrorsPlay({super.key, required this.onGoal});

  final VoidCallback onGoal;

  @override
  State<ErrorsPlay> createState() => _ErrorsPlayState();
}

class _ErrorsPlayState extends State<ErrorsPlay> {
  final _timers = <Timer>[];
  final _subscriptions = <StreamSubscription<String>>[];
  List<String> _listenLog = [];
  List<String> _awaitForLog = [];
  bool _listenDone = false;
  bool _awaitForDone = false;

  Stream<String> _source() {
    final controller = StreamController<String>();
    void at(int step, void Function() send) => _timers.add(
      Timer(Duration(milliseconds: 350 * step), () {
        if (!controller.isClosed) send();
      }),
    );
    at(1, () => controller.add('1️⃣'));
    at(2, () => controller.add('2️⃣'));
    at(3, () => controller.addError('💣'));
    at(4, () => controller.add('3️⃣'));
    at(5, controller.close);
    return controller.stream;
  }

  void _runListen() {
    setState(() => _listenLog = []);
    _subscriptions.add(
      _source().listen(
        (value) => setState(() => _listenLog.add('✅ $value')),
        onError: (Object error) => setState(() => _listenLog.add('❌ $error')),
        onDone: () {
          setState(() {
            _listenLog.add('🏁 done');
            _listenDone = true;
          });
          _check();
        },
      ),
    );
  }

  Future<void> _runAwaitFor() async {
    setState(() => _awaitForLog = []);
    try {
      await for (final value in _source()) {
        if (!mounted) return;
        setState(() => _awaitForLog.add('✅ $value'));
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _awaitForLog.add('💥 $error thrown: the loop stopped'));
    }
    if (!mounted) return;
    setState(() => _awaitForDone = true);
    _check();
  }

  void _check() {
    if (_listenDone && _awaitForDone) widget.onGoal();
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ErrorLane(
            title: 'listen()',
            log: _listenLog,
            action: (label: '▶️ Run', onPressed: _runListen),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ErrorLane(
            title: 'await for',
            log: _awaitForLog,
            action: (label: '▶️ Run', onPressed: _runAwaitFor),
          ),
        ),
      ],
    );
  }
}

class _ErrorLane extends StatelessWidget {
  const _ErrorLane({
    required this.title,
    required this.log,
    required this.action,
  });

  final String title;
  final List<String> log;
  final ({String label, VoidCallback? onPressed}) action;

  @override
  Widget build(BuildContext context) {
    return Stage(
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in log)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 250),
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(12 * (1 - t), 0),
                      child: child,
                    ),
                  ),
                  child: Text(line),
                ),
            ],
          ),
        ),
        ActionRow(actions: [action]),
      ],
    );
  }
}

extension on List<String> {
  Iterable<String> takeLast(int count) =>
      length <= count ? this : sublist(length - count);
}
