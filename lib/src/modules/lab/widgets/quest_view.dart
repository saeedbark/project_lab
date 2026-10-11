import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:project_lab/src/core/theme/theme.dart';
import 'package:project_lab/src/modules/lab/models/quest.dart';
import 'package:project_lab/src/modules/lab/providers/quest_progress.dart';

/// The game screen for a [Quest]: progress line, the current step, and a
/// celebration each time a step is cleared.
///
/// Everything a lesson does not have to write lives here, so a new quest is
/// only data plus its playgrounds.
class QuestView extends StatefulWidget {
  const QuestView({super.key, required this.progress});

  final QuestProgress progress;

  @override
  State<QuestView> createState() => _QuestViewState();
}

class _QuestViewState extends State<QuestView> {
  /// Bumped on every clear; a new key replays the burst.
  int _bursts = 0;
  bool _wasCleared = false;
  final _scroll = ScrollController();
  Timer? _reveal;

  QuestProgress get _progress => widget.progress;

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onProgress);
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgress);
    _reveal?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onProgress() {
    final cleared = _progress.cleared;
    if (cleared && !_wasCleared) {
      _bursts++;
      // Bring Continue into view once the cleared bar has grown in (its
      // AnimatedSize takes 300 ms), so nobody has to hunt for it.
      _reveal?.cancel();
      _reveal = Timer(const Duration(milliseconds: 320), () {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      });
    } else if (!cleared && _wasCleared && _scroll.hasClients) {
      // A new level starts at its top.
      _scroll.jumpTo(0);
    }
    _wasCleared = cleared;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _progress,
      builder: (context, _) {
        final step = _progress.current;
        return Stack(
          children: [
            Column(
              children: [
                _Header(progress: _progress),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.06),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: switch (step) {
                            null => _FinishCard(
                              key: const ValueKey('finish'),
                              progress: _progress,
                            ),
                            Play() => _PlayCard(
                              key: ValueKey(_progress.index),
                              step: step,
                              progress: _progress,
                            ),
                            Quiz() => _QuizCard(
                              key: ValueKey(_progress.index),
                              step: step,
                              progress: _progress,
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_bursts > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: _Burst(
                    key: ValueKey(_bursts),
                    big: _progress.index == _progress.steps.length - 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Header: level, XP and the progress line ──────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.progress});

  final QuestProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = progress.steps.length;
    final level = progress.finished
        ? 'All $total levels cleared'
        : 'Level ${progress.index + 1} of $total';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(level, style: theme.textTheme.titleSmall),
                  ),
                  _Pill(text: '⭐ ${progress.stars}/${progress.quizCount}'),
                  const SizedBox(width: 8),
                  _AnimatedXp(xp: progress.xp),
                ],
              ),
              const SizedBox(height: 12),
              _ProgressLine(percent: progress.percent),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedXp extends StatelessWidget {
  const _AnimatedXp({required this.xp});

  final int xp;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: xp.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, _) => _Pill(text: '⚡ ${value.round()} XP'),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// A gradient bar from 0 to 100%, with a rocket riding its tip.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final game = LabColors.of(context).game;
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: percent),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final done = value >= 0.999;
        return Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const rocket = 22.0;
                  final width = constraints.maxWidth;
                  return SizedBox(
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: track,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Container(
                          height: 12,
                          width: math.max(12, width * value),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: game),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Positioned(
                          left: (width * value - rocket / 2).clamp(
                            0,
                            width - rocket,
                          ),
                          child: Text(
                            done ? '🏁' : '🚀',
                            style: const TextStyle(fontSize: rocket - 4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              child: Text(
                '${(value * 100).round()}%',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Step cards ───────────────────────────────────────────────────────────

/// The frame every step shares: coloured badge, emoji, title.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.accent,
    required this.kind,
    required this.step,
    required this.children,
  });

  final Color accent;
  final String kind;
  final QuestStep step;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$kind · +${step.xp} XP',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(step.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PlayCard extends StatelessWidget {
  const _PlayCard({super.key, required this.step, required this.progress});

  final Play step;
  final QuestProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = LabColors.of(context).game[progress.index % 5];
    return _StepCard(
      accent: accent,
      kind: 'PLAY',
      step: step,
      children: [
        Text(step.intro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        _GoalLine(goal: step.goal, done: progress.cleared, accent: accent),
        const SizedBox(height: 16),
        // Built once per level (the card is keyed by index), so the
        // playground keeps its state while the progress around it changes.
        _Playground(builder: step.builder, onGoal: progress.reachGoal),
        _ClearedBar(progress: progress, accent: accent),
      ],
    );
  }
}

class _Playground extends StatefulWidget {
  const _Playground({required this.builder, required this.onGoal});

  final Widget Function(VoidCallback onGoal) builder;
  final VoidCallback onGoal;

  @override
  State<_Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<_Playground> {
  late final Widget _child = widget.builder(widget.onGoal);

  @override
  Widget build(BuildContext context) => _child;
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({
    required this.goal,
    required this.done,
    required this.accent,
  });

  final String goal;
  final bool done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final success = LabColors.of(context).success;
    final color = done ? success : accent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              done ? '✅' : '🎯',
              key: ValueKey(done),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              goal,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Level cleared" and the Continue button, sliding in when a step is done.
class _ClearedBar extends StatelessWidget {
  const _ClearedBar({required this.progress, required this.accent});

  final QuestProgress progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final step = progress.current!;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: !progress.cleared
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '🎉 Level cleared! +${_earned(step)} XP',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LabColors.of(context).success,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: progress.next,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                  ),
                ],
              ),
            ),
    );
  }

  int _earned(QuestStep step) => step is Quiz && progress.picked.length == 1
      ? step.xp + QuestProgress.firstTryBonus
      : step.xp;
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({super.key, required this.step, required this.progress});

  final Quiz step;
  final QuestProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = LabColors.of(context).game[progress.index % 5];
    final code = step.code;
    return _StepCard(
      accent: accent,
      kind: 'QUIZ',
      step: step,
      children: [
        Text(step.question, style: theme.textTheme.titleMedium),
        if (code != null) ...[const SizedBox(height: 12), _CodeBlock(code)],
        const SizedBox(height: 16),
        for (final (index, choice) in step.choices.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Choice(
              label: choice,
              letter: String.fromCharCode(65 + index),
              state: switch ((progress.picked.contains(index), index)) {
                (true, final i) when i == step.answer => _ChoiceState.right,
                (true, _) => _ChoiceState.wrong,
                _ when progress.cleared => _ChoiceState.idle,
                _ => _ChoiceState.open,
              },
              accent: accent,
              onTap: () => progress.answer(index),
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: !progress.cleared
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LabColors.of(context).success
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '💡 ${step.why}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
        ),
        _ClearedBar(progress: progress, accent: accent),
      ],
    );
  }
}

enum _ChoiceState { open, wrong, right, idle }

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.letter,
    required this.state,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String letter;
  final _ChoiceState state;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final success = LabColors.of(context).success;
    final (border, fill, mark) = switch (state) {
      _ChoiceState.right => (success, success.withValues(alpha: 0.15), '✅'),
      _ChoiceState.wrong => (
        colors.error,
        colors.error.withValues(alpha: 0.12),
        '❌',
      ),
      _ChoiceState.open => (colors.outlineVariant, colors.surface, letter),
      _ChoiceState.idle => (colors.outlineVariant, colors.surface, letter),
    };
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: accent.withValues(alpha: 0.08),
          onTap: state == _ChoiceState.open ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    mark,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      ),
    );
    if (state != _ChoiceState.wrong) return tile;
    // A wrong pick shakes once: a damped sine, played when it first shows.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * 8 * (1 - t), 0),
        child: child,
      ),
      child: tile,
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'Consolas',
          fontFamilyFallback: ['monospace'],
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}

class _FinishCard extends StatelessWidget {
  const _FinishCard({super.key, required this.progress});

  final QuestProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = LabColors.of(context).game;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            for (final color in game.take(3)) color.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.2, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: const Text('🏆', style: TextStyle(fontSize: 88)),
          ),
          const SizedBox(height: 12),
          Text(
            'Quest complete!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Badge earned: ${progress.quest.badge}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _Pill(text: '⚡ ${progress.xp} XP'),
              _Pill(
                text: '⭐ ${progress.stars}/${progress.quizCount} first try',
              ),
              _Pill(text: '✅ ${progress.steps.length} levels'),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: progress.restart,
            icon: const Icon(Icons.replay),
            label: const Text('Play again'),
          ),
        ],
      ),
    );
  }
}

// ── Celebration ──────────────────────────────────────────────────────────

/// Emoji that burst from the top centre and fall away. Played once per key.
class _Burst extends StatefulWidget {
  const _Burst({super.key, required this.big});

  final bool big;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  static const _emoji = ['🎉', '✨', '⭐', '🎊', '💫', '🌟'];

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final List<({double angle, double speed, String emoji, double spin})>
  _pieces;

  @override
  void initState() {
    super.initState();
    // Seeded: the same burst every time, which keeps golden-free tests and
    // screenshots stable.
    final random = math.Random(widget.key.hashCode);
    _pieces = [
      for (var i = 0; i < (widget.big ? 40 : 18); i++)
        (
          angle: -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 0.9,
          speed: 220 + random.nextDouble() * 260,
          emoji: _emoji[random.nextInt(_emoji.length)],
          spin: (random.nextDouble() - 0.5) * 6,
        ),
    ];
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honour "reduce motion": the cleared bar still says it.
    if (MediaQuery.of(context).disableAnimations) return const SizedBox();
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (t >= 1) return const SizedBox();
          final origin = Offset(constraints.maxWidth / 2, 110);
          return Stack(
            children: [
              for (final piece in _pieces)
                Positioned(
                  left:
                      origin.dx + math.cos(piece.angle) * piece.speed * t - 12,
                  top:
                      origin.dy +
                      math.sin(piece.angle) * piece.speed * t +
                      420 * t * t,
                  child: Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: Transform.rotate(
                      angle: piece.spin * t,
                      child: Text(
                        piece.emoji,
                        style: TextStyle(fontSize: widget.big ? 30 : 24),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
