import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:project_lab/src/core/utils/trace.dart';

typedef TraceEvent = ({Duration at, TraceLayer layer, String message});

/// Collects the events a demo emits so the lesson screen can show them.
class TraceLog extends ChangeNotifier {
  final _clock = Stopwatch()..start();
  final _events = <TraceEvent>[];
  bool _notifyScheduled = false;
  bool _disposed = false;

  List<TraceEvent> get events => List.unmodifiable(_events);

  /// Matches the `Trace` signature, so `log.add` can be passed as one.
  void add(TraceLayer layer, String message) {
    if (_disposed) return;
    _events.add((at: _clock.elapsed, layer: layer, message: message));
    // Widgets trace from inside build(), where notifying synchronously would
    // mark the trace panel dirty mid-frame. A microtask runs after the frame.
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  void clear() {
    _events.clear();
    _clock.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
