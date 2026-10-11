import 'package:flutter/foundation.dart';

import 'package:project_lab/src/modules/lab/models/quest.dart';

/// Where the learner is in a [Quest], and the rules for moving on.
///
/// A step is *active*, then *cleared* (the celebration shows), and [next]
/// moves on. Kept apart from the widgets so the rules are testable without
/// pumping a single frame.
class QuestProgress extends ChangeNotifier {
  QuestProgress(this.quest);

  final Quest quest;

  /// Extra points for a quiz answered right on the first try.
  static const firstTryBonus = 5;

  int _index = 0;
  bool _cleared = false;
  int _xp = 0;
  int _stars = 0;
  final _picked = <int>{};

  List<QuestStep> get steps => quest.steps;
  int get index => _index;
  bool get finished => _index >= steps.length;
  QuestStep? get current => finished ? null : steps[_index];

  /// The current step is done and waiting for [next].
  bool get cleared => _cleared;

  /// 0.0 to 1.0. A cleared step counts as done before Continue is pressed,
  /// so the line fills at the moment of success.
  double get percent =>
      steps.isEmpty ? 1 : (_index + (_cleared ? 1 : 0)) / steps.length;

  int get xp => _xp;

  /// Quizzes answered right on the first try.
  int get stars => _stars;
  int get quizCount => steps.whereType<Quiz>().length;

  /// Choices tried on the current quiz, wrong ones included.
  Set<int> get picked => Set.unmodifiable(_picked);

  /// The current [Play] step's goal was reached.
  void reachGoal() {
    final step = current;
    if (step is! Play || _cleared) return;
    _clear(step.xp);
  }

  /// Returns whether [choice] is right. A wrong choice can be retried; it
  /// costs only the first-try star.
  bool answer(int choice) {
    final step = current;
    if (step is! Quiz) return false;
    final right = choice == step.answer;
    if (_cleared || _picked.contains(choice)) return right;
    final firstTry = _picked.isEmpty;
    _picked.add(choice);
    if (!right) {
      notifyListeners();
    } else {
      if (firstTry) _stars++;
      _clear(step.xp + (firstTry ? firstTryBonus : 0));
    }
    return right;
  }

  void next() {
    if (!_cleared) return;
    _index++;
    _cleared = false;
    _picked.clear();
    notifyListeners();
  }

  void restart() {
    _index = 0;
    _cleared = false;
    _xp = 0;
    _stars = 0;
    _picked.clear();
    notifyListeners();
  }

  void _clear(int points) {
    _cleared = true;
    _xp += points;
    notifyListeners();
  }
}
