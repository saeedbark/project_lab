# f02 · Layers and the repository

Career-OS week 2 (w2t1, w2t3, w2t6). The feature is a shelf price audit: an
auditor walks an aisle and records whether each shelf label matches the price
in the system.

## The shape

The module uses the same five folders as Wasl and Hadrami_AI:

```
lib/src/modules/price_audit/
  models/      AuditEntry, Price, AuditEntryDto
  services/    PriceApi, FakePriceApi, PriceAuditRepository (+Impl)
  providers/   AuditViewModel (f02) · providers + AuditController (f03)
  pages/       PlainAuditPage · RiverpodAuditPage
  widgets/     AuditListView, AislePicker
```

The layers are still there; they are import directions instead of folders:

```
pages, widgets  →  providers  →  services  →  models
  (UI layer)      (UI logic)   (data layer)  (shared types)
```

Career-OS and *Clean Architecture* say `data / domain / ui`. The mapping, so
you can speak both vocabularies in an interview:

| Here | Clean Architecture | Flutter architecture guide |
|---|---|---|
| `models/` (entity, value type) | domain | domain models |
| `models/audit_entry_dto.dart`, `services/` | data | data layer: services + repositories |
| `providers/` | presentation logic | view models |
| `pages/`, `widgets/` | presentation | views |

Nothing in the tree stops a page from importing `fake_price_api.dart`. So the
rule is written as a test: `test/modules/price_audit/import_rules_test.dart`
fails if a folder imports one it should not.

## Decisions, and what was rejected

**Five flat folders, not `data/domain/presentation`.**
Rejected: the nested three-layer tree this lesson first used. It makes the
Dependency Rule visible in the file tree, which is its real advantage. It
lost because every other project of yours uses the flat layout, a module with
eight files does not need two levels of folders, and the rule can be enforced
by a test instead. When the nested tree wins: a large module where `services/`
grows past a dozen files, or a team that will not keep a convention.

**The repository is an interface in its own file.**
Wasl's services are concrete classes, and tests override the provider that
builds them. That is enough when there is one implementation. Here the
interface earns its place for one reason: f07 adds an offline-first
implementation behind the same contract, and neither the view model nor the
controller should change when it does. The rule of thumb is Wasl's own:
add the abstraction on the second implementation, not before. We are about to
have a second.

**A DTO separate from the entity.**
The wire sends `system_price: "12.50"` (snake_case, string). The entity holds
`Price(1250)`. `AuditEntryDto` is the single file that knows both. The
rejected alternative is `AuditEntry.fromJson`: shorter, but then a backend
change edits the entity, and the entity cannot be built in a test without
thinking about JSON. It sits in `models/` beside the entity; the import test
keeps it out of pages and widgets only by the contract rule, so treat it as
data-layer code that happens to live there.
When the DTO is *not* worth it: the wire shape and the entity are identical
and you own the backend. Wasl does exactly that with freezed models.

**The repository throws `Failure`; it does not return `Result<T>`.**
`_guard` converts every transport exception into a sealed `Failure`. The
alternative is returning `Result<AuditEntry, Failure>` so the compiler forces
callers to handle errors. It was rejected here because the caller in f03 is
an `AsyncNotifier`, whose `AsyncValue` already *is* that result type; a
`Result` would be unwrapped and immediately rethrown. `Result` earns its
place when the caller is plain Dart code that must branch on the outcome.
Lesson f04 compares the two on the same code.

**A sealed `Failure`, where Wasl has one `AppException(message)`.**
Wasl's services write the user-facing sentence at the point of failure, which
is less code. The sealed type keeps *what happened* separate from *what to
say*: the UI can offer "Retry" for a timeout and "Check your network" for
offline, and the message lives with the other UI copy
(`lib/src/widgets/failure_view.dart`). Pick the single exception when every
failure is handled the same way.

**`_guard` catches `Exception`, not `Error`.**
An `Error` is a bug (a bad cast, a null check). Mapping it to
`UnexpectedFailure` would show the user "something went wrong" and hide the
stack trace from you. Let bugs crash.

**No use-case classes.**
A `LoadAisleUseCase` that only calls `repository.loadAisle` adds a file and a
hop and no decision. The Flutter architecture guide says the same: add a
domain *logic* layer when logic is reused across view models or combines
several repositories. The status rule (`AuditEntry.status`) is domain logic,
and it sits on the entity.

**A sealed view state, not three fields.**
`bool loading; Failure? error; List<AuditEntry>? entries` allows
`loading == true && error != null`. `AuditViewState` has three subclasses, so
that combination cannot be constructed and the `switch` in the page is
checked for exhaustiveness.

**Money is `Price`, an extension type over `int` minor units.**
Not `double`: `0.1 + 0.2 != 0.3`. Not a full class: the extension type is an
`int` at runtime, so it costs nothing, yet `Price` and a quantity cannot be
swapped by accident at compile time. The limit: it is erased at runtime, so
`x is Price` is just `x is int`.

## What the hand-written view model has to do

Read `providers/audit_view_model.dart` for these three, because f03 deletes
them:

1. `_loadId`: two loads can be in flight; the older answer must not win.
2. `_disposed`: an answer can arrive after the page is gone, and
   `notifyListeners` on a disposed notifier throws.
3. The `AuditViewState` hierarchy itself.

## One thing the trace shows that the code does not

On **Slow**, the repository times out at 3 s and the UI shows the timeout
message, but the trace prints `200 OK` at 6 s. `Future.timeout` stops
*waiting*; it does not cancel the request. For a read that is wasted work.
For `recordShelfPrice` it means the user is told "not saved" and the server
saved it anyway. Real cancellation and idempotent writes are f04's subject.

## When this architecture is the wrong choice

- A prototype or a two-page app: five folders per module is ceremony.
- The app is a thin view over one backend you control and the DTO equals the
  entity: drop the DTO and the interface, as Wasl does.
- The cost is always the same: more files, more hops to follow, and mapping
  code that must be kept in step.

## Interview phrasing

"I organise feature-first: each module has models, services, providers, pages
and widgets, and imports only flow downward through that list. Pages depend
on a repository interface, the DTO absorbs wire changes, and the repository
is the one place where transport exceptions become a sealed failure type, so
the UI switches over a closed set instead of catching strings."
