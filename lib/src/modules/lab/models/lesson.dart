import 'package:flutter/widgets.dart';

import 'package:project_lab/src/modules/lab/providers/trace_log.dart';

enum Track {
  dart('Dart'),
  flutter('Flutter'),
  foundations('Foundations'),
  ai('AI');

  const Track(this.label);

  final String label;
}

/// One file to read, in order, and what to look for in it.
typedef ReadingStep = ({String path, String lookFor});

typedef Source = ({String title, String url});

/// One work window (9 to 1): three 50-minute periods over one runnable demo.
///
/// Period 1 runs the demo and reads [readingPath]; period 2 reads
/// [notesPath] and [testPath] and questions the decisions; period 3 is
/// [explain] aloud, then the primary [sources].
class Lesson {
  const Lesson({
    required this.id,
    required this.track,
    required this.title,
    required this.goal,
    required this.careerOs,
    required this.replaces,
    required this.readingPath,
    required this.testPath,
    required this.watchFor,
    required this.explain,
    required this.sources,
    required this.notesPath,
    required this.demo,
  });

  final String id;
  final Track track;
  final String title;

  /// "After this session I can …", in one sentence.
  final String goal;

  /// Where this sits in Career-OS (week and task ids).
  final String careerOs;

  /// The reading this session stands in for.
  final String replaces;

  /// The production code, in the order it should be read.
  final List<ReadingStep> readingPath;

  /// The tests that pin the behaviour down; read after the notes.
  final List<ReadingStep> testPath;

  /// Things to try in the demo while watching the trace.
  final List<String> watchFor;

  /// Questions to answer aloud, in English, before closing the session.
  final List<String> explain;

  /// Primary sources for going deeper afterwards.
  final List<Source> sources;

  final String notesPath;

  final Widget Function(TraceLog trace) demo;
}
