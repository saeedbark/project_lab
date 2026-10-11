import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:project_lab/src/core/theme/theme.dart';

/// What the pipe between a producer and a listener is doing.
enum PipeState { idle, flowing, paused, cut }

/// Starts emoji travelling down an [EmojiPipe]. The playgrounds call
/// [launch] from the real stream listener, so a marble on screen is an event
/// that was really delivered.
class PipeController extends ChangeNotifier {
  final _launches = <String>[];

  void launch(String emoji) {
    _launches.add(emoji);
    notifyListeners();
  }

  List<String> _take() {
    final taken = List.of(_launches);
    _launches.clear();
    return taken;
  }
}

/// Producer on the left, listener on the right, events as emoji in between.
///
/// When [state] is paused a clamp sits in the middle with a bucket of
/// [buffered] events; when cut, the pipe is broken.
class EmojiPipe extends StatefulWidget {
  const EmojiPipe({
    super.key,
    required this.controller,
    required this.producer,
    required this.listener,
    required this.state,
    this.buffered = 0,
  });

  final PipeController controller;
  final String producer;
  final String listener;
  final PipeState state;
  final int buffered;

  @override
  State<EmojiPipe> createState() => _EmojiPipeState();
}

class _EmojiPipeState extends State<EmojiPipe>
    with SingleTickerProviderStateMixin {
  static const _travel = Duration(milliseconds: 700);

  late final Ticker _ticker = createTicker(_tick);
  Duration _now = Duration.zero;
  final _marbles = <({String emoji, Duration start})>[];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onLaunch);
  }

  @override
  void didUpdateWidget(EmojiPipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onLaunch);
      widget.controller.addListener(_onLaunch);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onLaunch);
    _ticker.dispose();
    super.dispose();
  }

  void _onLaunch() {
    // Several events at once (a resume pours the bucket) leave in a row
    // instead of on top of each other.
    var start = _now;
    if (_marbles.isNotEmpty && start - _marbles.last.start < _gap) {
      start = _marbles.last.start + _gap;
    }
    for (final emoji in widget.controller._take()) {
      _marbles.add((emoji: emoji, start: start));
      start += _gap;
    }
    if (!_ticker.isActive) _ticker.start();
    setState(() {});
  }

  static const _gap = Duration(milliseconds: 140);

  void _tick(Duration elapsed) {
    // Ticker time restarts from zero on every start(); marbles are stored in
    // that same clock, so keep it continuous across stops.
    _now = elapsed + _offset;
    _marbles.removeWhere((m) => _now - m.start > _travel);
    if (_marbles.isEmpty) {
      _offset = _now;
      _ticker.stop();
    }
    setState(() {});
  }

  Duration _offset = Duration.zero;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final game = LabColors.of(context).game;
    final cut = widget.state == PipeState.cut;
    final paused = widget.state == PipeState.paused;
    final flowing = widget.state == PipeState.flowing;
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          _End(emoji: widget.producer, active: !cut),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: cut || widget.state == PipeState.idle
                            ? colors.surfaceContainerHighest
                            : null,
                        gradient: flowing || paused
                            ? LinearGradient(
                                colors: [
                                  game[0].withValues(alpha: 0.6),
                                  game[3].withValues(alpha: 0.6),
                                ],
                              )
                            : null,
                      ),
                    ),
                    if (cut)
                      Positioned(
                        left: width / 2 - 14,
                        child: const Text('✂️', style: TextStyle(fontSize: 26)),
                      ),
                    if (paused)
                      Positioned(
                        left: width / 2 - 20,
                        top: -2,
                        child: _Bucket(count: widget.buffered),
                      ),
                    for (final marble in _marbles)
                      if (_now >= marble.start)
                        Positioned(
                          left:
                              (width - 26) *
                              ((_now - marble.start).inMicroseconds /
                                      _travel.inMicroseconds)
                                  .clamp(0, 1),
                          child: Text(
                            marble.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          _End(emoji: widget.listener, active: true),
        ],
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({required this.emoji, required this.active});

  final String emoji;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: active ? 1 : 0.35,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

class _Bucket extends StatelessWidget {
  const _Bucket({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⏸️', style: TextStyle(fontSize: 18)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.tertiaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '🪣 $count',
            style: TextStyle(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// The tinted box every playground sits in.
class Stage extends StatelessWidget {
  const Stage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// A line of state, e.g. "📦 made 3 · 👀 received 1".
class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          text,
          key: ValueKey(text),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// The playgrounds' buttons: one style, wrapping on a narrow screen.
class ActionRow extends StatelessWidget {
  const ActionRow({super.key, required this.actions});

  final List<({String label, VoidCallback? onPressed})> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final action in actions)
          FilledButton.tonal(
            onPressed: action.onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(action.label),
          ),
      ],
    );
  }
}
