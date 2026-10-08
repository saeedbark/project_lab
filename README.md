# project_lab

A guided technical learning laboratory. Each lesson fills one work window
(9 to 1), three 50-minute periods built around a complete, running implementation: run the demo and watch the
trace, read the code in a given order, question the decisions, then explain
it aloud.

What gets a lesson is decided by Career-OS; see
[docs/CAREER_OS_MAP.md](docs/CAREER_OS_MAP.md).

## Run

```bash
flutter run -d windows
```

```bash
flutter test
```

## A work window

Open a lesson from the home page. The left pane is the plan.

| Period | What you do |
|---|---|
| 1 · Run it and read it | Demo with the trace pane (10 min), then the code in the listed order (40 min) |
| 2 · Question it | The lesson's `NOTES.md` (20 min), its tests (15 min), then ask Claude what breaks if a decision is reversed (15 min) |
| 3 · Say it, then the source | Answer the questions aloud in English (15 min), read the primary source (30 min), write one line and tick the Career-OS task (5 min) |

A short day still works: the periods are independent, so a lesson can be
spread over two or three days.

## Layout

Feature-first, the same layout as Wasl.

```
lib/src/app.dart        themes (dark by default, toggle in the app bar)
lib/src/core/           errors, theme, utils
lib/src/modules/lab/    the shell: lesson pages, trace panel
lib/src/modules/price_audit/{models,pages,providers,services,widgets}/
lib/src/lessons/        one folder per lesson: lesson.dart + NOTES.md
lib/src/widgets/        shared widgets
test/                   the tests are part of each reading path
```
