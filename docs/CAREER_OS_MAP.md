# Career-OS → project_lab

Which Career-OS work the lab compresses, which it leaves alone, and the order
lessons get built in. Career-OS started on 2026-09-19 (week 1).

## Built

| Lesson | Career-OS | Replaces (reading) | Then go to the source for |
|---|---|---|---|
| f02 Layers and the repository | W2 · w2t1, w2t3, w2t6 | First pass of the Flutter architecture guide; Dependency Rule chapters of *Clean Architecture* | The guide's case study and recommendations |
| f03 Riverpod: AsyncNotifier and AsyncValue | W2 · w2t2, w2t4 · month-1 gate | Riverpod getting started, Notifier, AsyncValue, family, autoDispose | "What's new in 3.0" |

## Planned, in build order

| Lesson | Career-OS | Notes |
|---|---|---|
| f04 The error's journey and the network layer | W3 · w3t2, w3t4, w3t5 | dio, interceptors, timeout with real cancellation, selective retry, `Result` vs throw |
| f05 Tests as design | W3 · w3t1, w3t3 | Fakes vs mocks, what each layer's test proves, one golden test |
| d01 Records and patterns | W1 · w1t1 | Backfill |
| d02 Sealed classes and exhaustiveness | W1 · w1t1, w1t4 | Backfill |
| d03 Future vs Stream | W1 · w1t2, w1t6, w1t7 | Backfill |
| f01 Three trees and rebuilds | W4 · w4t1 | Widget / Element / RenderObject, only as far as rebuild cost needs |
| f06 Rebuild control | W4 · w4t1 | `const`, splitting widgets, `select`; rebuild counts in the trace |
| f07 Offline-first sync | W4 · w4t3 | drift + Supabase, on the price-audit feature |
| d04 Event loop and isolates | Foundations L2 (weeks 4–9) | Stands in for OSTEP Virtualization and Concurrency |
| f08 Riverpod code generation | W2 "should" | What `@riverpod` generates, against f03's hand-written providers |
| ai01… LLM client side | W9–12 | Mocked responses; the real build is Sales Copilot |

## Not in the lab, on purpose

| Career-OS item | Why it stays where it is |
|---|---|
| `build`, `evidence` and `gate` tasks (dart-drills, hadrami-ai feature, Tech Ops Log) | Career-OS rule: code you cannot explain is not done. These are built by hand. |
| SQL (pgexercises, *Learning SQL*) | The gate is writing a window function from memory. Reading queries does not get there. |
| Python, FastAPI, Docker | Different runtime; they live in `sales-api`. |
| *The Pragmatic Programmer*, system design, *AI Engineering* | Mindset and interview material; also the English reading practice. |
| Git (foundations L1) | Learned on real repositories. |
| System Map, the daily workplace question | Cannot be done anywhere but at work. |

## Postponed (Career-OS `later` / NOT NOW)

Custom RenderObjects, shaders, advanced animations, Bloc/GetX, Hooks, Melos,
integration and E2E tests, agent frameworks, MCP, separate vector databases.
