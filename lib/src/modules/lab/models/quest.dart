import 'package:flutter/widgets.dart';

/// A lesson as a game: steps that unlock one at a time, from 0 to 100%.
///
/// Adding a quest to a lesson is declarative. Quizzes are plain data; a
/// [Play] step is one widget that calls `onGoal` when the learner has done
/// the thing. The shell supplies the progress line, XP, celebrations and the
/// finish screen, so a new lesson writes none of that.
class Quest {
  const Quest({required this.badge, required this.steps});

  /// What the learner earns at 100%, emoji first, e.g. '🌊 Stream Tamer'.
  final String badge;
  final List<QuestStep> steps;
}

sealed class QuestStep {
  const QuestStep({required this.emoji, required this.title, required this.xp});

  final String emoji;
  final String title;
  final int xp;
}

/// An interactive playground. [goal] says what passes the level; the widget
/// from [builder] calls `onGoal` once that has happened. It may call it more
/// than once; only the first call counts.
final class Play extends QuestStep {
  const Play({
    required super.emoji,
    required super.title,
    required this.intro,
    required this.goal,
    required this.builder,
    super.xp = 20,
  });

  /// One or two sentences: the idea this level shows.
  final String intro;
  final String goal;
  final Widget Function(VoidCallback onGoal) builder;
}

/// A multiple-choice question. [why] appears once the right choice is
/// picked, so the explanation lands right after the guess.
final class Quiz extends QuestStep {
  const Quiz({
    required super.emoji,
    required super.title,
    required this.question,
    required this.choices,
    required this.answer,
    required this.why,
    this.code,
    super.xp = 10,
  });

  final String question;

  /// Optional snippet the question is about, shown in a code block.
  final String? code;
  final List<String> choices;

  /// Index into [choices].
  final int answer;
  final String why;
}
