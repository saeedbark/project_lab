# project_lab

A personal technical learning laboratory. Saeed studies implementations that
Claude builds; he does not complete exercises here.

## Source of truth

Career-OS (`C:\Users\hp\Downloads\career-roadmap.html`, a single HTML file
with the roadmap data in its `<script>`) decides what is learned and when.
`docs/CAREER_OS_MAP.md` maps its tasks to lessons. Re-read the relevant week
before adding a lesson; do not add topics Career-OS lists under `later` or
NOT NOW.

## Rules

- **No exercises.** Never leave "now implement X" or TODOs for the learner.
  Every lesson ships complete, running and tested.
- **The lab compresses reading, not building.** Career-OS `build`,
  `evidence` and `gate` tasks (hadrami-ai, Tech Ops Log, dart-drills) are
  done by hand elsewhere. Do not build those projects here, and keep the
  reference feature a different domain from Tech Ops Log.
- **Lab time is the Career-OS work window (9 to 1), not the evening**:
  three 50-minute periods. One lesson fills one window. Period 1: demo
  (10) + code reading path (40). Period 2: NOTES.md (20) + test path (15) +
  "why not…?" with Claude (15). Period 3: explain aloud in English (15) +
  the primary source (30) + one-line close (5). The evening stays for the
  hand-built Career-OS work.
- **Lessons are paths through real code**, not isolated snippets. Prefer
  extending the reference feature over starting a new toy example.
- **Code is reading material.** Comments explain the decision and the
  rejected alternative, never restate the line. Tests are part of the
  reading path.
- **Verify library behavior against the installed source** (pub cache)
  before stating it in NOTES.md, and pin it with a test where possible.
- `master-lab` is a separate project. Never modify it.

## Layout

Feature-first, the same layout as Wasl and Hadrami_AI.

```
lib/
├── main.dart
└── src/
    ├── app.dart                  # LabApp: themes (dark by default) + home
    ├── core/
    │   ├── errors/failure.dart   # the sealed Failure type
    │   ├── theme/                # AppTheme, LabColors, ThemeModeScope
    │   └── utils/trace.dart      # Trace function type
    ├── modules/
    │   ├── lab/                  # the shell: lesson model, pages, trace panel
    │   └── price_audit/          # the reference feature
    │       └── {models,pages,providers,services,widgets}/
    ├── lessons/
    │   ├── lesson_registry.dart
    │   └── <track>/<id>_<name>/{lesson.dart, NOTES.md}
    └── widgets/                  # shared across modules
test/modules/<feature>/           # flat, one folder per module
```

## Conventions

- **Package imports** (`package:project_lab/src/...`), sorted; both are lints.
- **Module layout** `lib/src/modules/<feature>/{models,pages,providers,services,widgets}/`.
  `providers/` holds state holders of any kind (Riverpod or `ChangeNotifier`).
  Pages are named `*_page.dart` / `*Page`.
- **Imports flow one way**: pages, widgets → providers → services → models.
  `test/modules/price_audit/import_rules_test.dart` enforces it; give a new
  module the same test.
- Modules must not import `modules/lab/` or `lessons/`; they receive a
  `Trace` function. Lessons are the composition roots.
- **Dark mode**: never hardcode a colour. Use `Theme.of(context).colorScheme`,
  or `LabColors.of(context)` for trace-layer and success colours.

## Adding a lesson

1. Build or extend the code under `lib/src/modules/` (or the lesson folder
   for language-only topics) with tests.
2. Add `lib/src/lessons/<track>/<id>_<name>/lesson.dart` and `NOTES.md`
   (decisions, rejected alternatives, when it is the wrong choice, interview
   phrasing).
3. Give it a game: `quest.dart` in the lesson folder, passed as `quest:`.
   Saeed studies by playing (colour, emoji, celebration, 0 to 100%), so
   every new lesson ships one. A quest is data: `Quiz` steps are plain
   values, and a `Play` step is one widget that calls `onGoal` when the
   learner has done the thing. Playgrounds run the real Dart objects (see
   `d03_future_vs_stream/playgrounds.dart`); the shell (`QuestView`) owns
   the progress line, XP, stars, confetti and the finish screen. No network
   toggles or trace reading in the game; that stays in the lab view.
   Test that every playground can be won (`test/lessons/d03_playgrounds_test.dart`).
4. Register it in `lib/src/lessons/lesson_registry.dart` and update
   `docs/CAREER_OS_MAP.md`.
5. `flutter analyze` and `flutter test` must be clean.

## Commands

- `flutter run -d windows` (or `-d chrome`)
- `flutter test`
- `flutter analyze`
