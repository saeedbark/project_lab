import 'package:project_lab/src/lessons/flutter/price_audit_demo.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';
import 'package:project_lab/src/modules/price_audit/pages/plain_audit_page.dart';
import 'package:project_lab/src/modules/price_audit/services/fake_price_api.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository_impl.dart';

const _module = 'lib/src/modules/price_audit';
const _tests = 'test/modules/price_audit';

final f02LayersRepository = Lesson(
  id: 'f02',
  track: Track.flutter,
  title: 'Layers and the repository',
  goal:
      'I can map the five folders of a module onto the three layers, say '
      'which way every import points, and defend what the repository is for.',
  careerOs: 'Week 2 · w2t1, w2t3, w2t6',
  replaces:
      'First pass through docs.flutter.dev/app-architecture and the '
      'Dependency Rule chapters of Clean Architecture.',
  watchFor: [
    'Load an aisle on Normal and follow one request down the trace and back '
        'up: ui → state → repository → dataSource.',
    'Switch to Offline, then 503, and press Retry. The data source throws a '
        'different exception each time; note where it becomes a Failure.',
    'Switch to Slow and load. The repository gives up after 3 seconds, yet '
        'the server still answers at 6. Nothing cancelled the request.',
    'On Slow, tap one aisle and then another at once. Find "dropped a stale '
        'response" in the trace.',
  ],
  readingPath: [
    (
      path: '$_module/models/audit_entry.dart',
      lookFor:
          'No Flutter import, no JSON. Status is computed from the prices, '
          'never stored.',
    ),
    (
      path: '$_module/services/price_audit_repository.dart',
      lookFor:
          'The contract, in a file of its own. Everything above services/ '
          'depends on this file and never on the implementation.',
    ),
    (
      path: '$_module/services/fake_price_api.dart',
      lookFor:
          'The wire format: snake_case keys, prices as strings. This is what '
          'the layers above must never see.',
    ),
    (
      path: '$_module/models/audit_entry_dto.dart',
      lookFor: 'The one place that knows both shapes. fromJson, then toDomain.',
    ),
    (
      path: '$_module/services/price_audit_repository_impl.dart',
      lookFor:
          '_guard: every transport exception leaves as a Failure. Note '
          'why it catches Exception and not Error.',
    ),
    (
      path: '$_module/providers/audit_view_model.dart',
      lookFor:
          'A sealed state instead of three fields, and the bookkeeping '
          '(_loadId, _disposed) that f03 will delete.',
    ),
    (
      path: 'lib/src/lessons/flutter/f02_layers_repository/lesson.dart',
      lookFor:
          'The composition root at the bottom of this file: the only place '
          'that names the concrete repository and API.',
    ),
  ],
  testPath: [
    (
      path: '$_tests/price_audit_repository_impl_test.dart',
      lookFor:
          'What a repository test proves, and that it needs no widget and no '
          'mock framework.',
    ),
    (
      path: '$_tests/import_rules_test.dart',
      lookFor:
          'The layering written as a test: which folder may import which. '
          'Folders no longer enforce it, so this does.',
    ),
  ],
  explain: [
    'Which of the five folders are the data layer, which the UI layer, '
        'and where did the domain layer go?',
    'What would break if the view model used AuditEntryDto directly?',
    'Why is the repository an interface when there is one implementation?',
    'What is the cost of these layers for a two-screen app?',
    'Follow an "offline" error from the data source to the text on screen.',
  ],
  sources: [
    (
      title: 'Flutter app architecture guide (read the case study next)',
      url: 'https://docs.flutter.dev/app-architecture',
    ),
    (
      title: 'Architecture recommendations',
      url: 'https://docs.flutter.dev/app-architecture/recommendations',
    ),
  ],
  notesPath: 'lib/src/lessons/flutter/f02_layers_repository/NOTES.md',
  // Composition root: the dependency graph is wired by hand, outermost
  // object first. Swap FakePriceApi for a real client and nothing above the
  // repository changes.
  demo: (trace) => PriceAuditDemo(
    trace: trace,
    builder: (api) => PlainAuditPage(
      repository: PriceAuditRepositoryImpl(api: api, trace: trace.add),
      aisles: FakePriceApi.aisles,
      trace: trace.add,
    ),
  ),
);
