import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_lab/src/lessons/flutter/price_audit_demo.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';
import 'package:project_lab/src/modules/price_audit/pages/riverpod_audit_page.dart';
import 'package:project_lab/src/modules/price_audit/providers/audit_providers.dart';
import 'package:project_lab/src/modules/price_audit/services/fake_price_api.dart';

const _module = 'lib/src/modules/price_audit';
const _tests = 'test/modules/price_audit';

final f03RiverpodAsync = Lesson(
  id: 'f03',
  track: Track.flutter,
  title: 'Riverpod: AsyncNotifier and AsyncValue',
  goal:
      'I can explain what AsyncValue holds during a first load, a refresh '
      'and a failed refresh, and what family and autoDispose do to a '
      'provider\'s lifetime.',
  careerOs: 'Week 2 · w2t2, w2t4 · month-1 gate: "explain AsyncValue"',
  replaces:
      'riverpod.dev getting started, Notifier, AsyncValue, family and '
      'autoDispose pages.',
  watchFor: [
    'Load Dairy, then press Refresh. The list stays; the trace says '
        '"AsyncData (isLoading)", not AsyncLoading.',
    'Go Offline and press Refresh. You get an AsyncError that still carries '
        'the old list, which is why the list is still on screen.',
    'Stay Offline and switch to Bakery: no previous data, so the error view '
        'shows. Press Retry and read "AsyncError (isLoading)".',
    'Switch aisles on Normal and find "AuditController(Dairy) disposed". '
        'That line is autoDispose; one controller per aisle is family.',
    'Record a shelf price while Offline. The save fails, the list is '
        'untouched, and the controller state never became an error.',
  ],
  readingPath: [
    (
      path: '$_module/providers/audit_providers.dart',
      lookFor:
          'The same dependency graph f02 wired by hand, declared as '
          'providers. Note the provider that throws unless overridden, and '
          'why retry is switched off.',
    ),
    (
      path: '$_module/providers/audit_controller.dart',
      lookFor:
          'Open audit_view_model.dart next to it. List what disappeared and '
          'which line of Riverpod replaced each piece.',
    ),
    (
      path: '$_module/pages/riverpod_audit_page.dart',
      lookFor:
          'The switch over AsyncValue: why data is matched before error, '
          'and why the notifier is read at tap time.',
    ),
    (
      path: 'lib/src/lessons/flutter/f03_riverpod_async/lesson.dart',
      lookFor:
          'The ProviderScope overrides at the bottom: dependency injection '
          'is two lines.',
    ),
  ],
  testPath: [
    (
      path: '$_tests/audit_controller_test.dart',
      lookFor:
          'A ProviderContainer with the repository overridden: state logic '
          'tested with no widget tree.',
    ),
    (
      path: '$_tests/riverpod_audit_page_test.dart',
      lookFor: 'Loading, error and data each pinned by a widget test.',
    ),
  ],
  explain: [
    'What are the three classes of AsyncValue, and why is isLoading a '
        'separate flag from AsyncLoading?',
    'After a failed refresh, what does the AsyncValue contain?',
    'ref.watch versus ref.read: which one belongs in build, and why?',
    'What does autoDispose cost the user when they return to an aisle?',
    'What did the hand-written view model need that the controller does not?',
  ],
  sources: [
    (
      title: 'Riverpod: getting started',
      url: 'https://riverpod.dev/docs/introduction/getting_started',
    ),
    (
      title: 'What changed in Riverpod 3.0 (retry, notifier lifetime)',
      url: 'https://riverpod.dev/docs/whats_new',
    ),
  ],
  notesPath: 'lib/src/lessons/flutter/f03_riverpod_async/NOTES.md',
  // Composition root, Riverpod style: override the two providers that have
  // no production default here, and the rest of the graph builds itself.
  demo: (trace) => PriceAuditDemo(
    trace: trace,
    builder: (api) => ProviderScope(
      overrides: [
        priceApiProvider.overrideWithValue(api),
        traceProvider.overrideWithValue(trace.add),
      ],
      child: const RiverpodAuditPage(aisles: FakePriceApi.aisles),
    ),
  ),
);
