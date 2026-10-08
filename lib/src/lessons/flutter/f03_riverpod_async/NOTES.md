# f03 · Riverpod: AsyncNotifier and AsyncValue

Career-OS week 2 (w2t2, w2t4) and the month-1 gate item "explain AsyncValue
and loading/error/success in English". Same feature, same models and
services as f02. Only the Riverpod files in `providers/` and `pages/` are new.
Written against Riverpod 3.4.

## What Riverpod replaced

Open `providers/audit_view_model.dart` beside `providers/audit_controller.dart`.

| Hand-written in f02 | Riverpod in f03 |
|---|---|
| `AuditViewState` sealed hierarchy | `AsyncValue<List<AuditEntry>>` |
| `_loadId` stale-response guard | results of a disposed or rebuilt provider are discarded |
| `_disposed` flag | `ref.mounted` |
| `selectAisle` + reload | `family`: one provider instance per aisle |
| `initState` / `dispose` in the page | `autoDispose` |
| constructor injection, wired in the lesson file | `ref.watch(priceAuditRepositoryProvider)` + `overrides` |

Nothing in `models/` or `services/` changed. That is the payoff of f02.

## AsyncValue is not three states

There are three *classes* (`AsyncData`, `AsyncError`, `AsyncLoading`) but each
can carry the previous value, the previous error and an `isLoading` flag.
What the demo shows, and `audit_controller_test.dart` pins down:

| Situation | Class | `value` | `error` | `isLoading` |
|---|---|---|---|---|
| First load | `AsyncLoading` | null | null | true |
| Loaded | `AsyncData` | list | null | false |
| Refresh in flight | `AsyncData` | old list | null | **true** |
| Refresh failed | `AsyncError` | **old list** | failure | false |
| First load failed | `AsyncError` | null | failure | false |
| Retry after that | `AsyncError` | null | failure | **true** |

This is why the page's `switch` is ordered the way it is.

**Matching on the class would be a bug.** `AsyncError(:final error) =>
FailureView` replaces a perfectly good list with an error page when a
background refresh fails. So the page matches on *content*:
`AsyncValue(:final value?)` first (any state that has data shows the list),
then `AsyncValue(error: final Failure failure)`, then the spinner.

**`.when()` was rejected** for the same reason: its defaults
(`skipLoadingOnRefresh`, `skipError`) encode these rules as boolean flags you
have to remember. A pattern `switch` puts the priority order on the page.

## Decisions

**`ref.watch` in `build`, `ref.read` in `recordShelfPrice`.**
`watch` registers a dependency: if the repository provider changed, the
controller would rebuild. `read` is a one-off lookup. Using `watch` inside a
method called from a button would register a dependency from a callback,
which is meaningless; using `read` inside `build` would miss updates.

**Saving does not go through `state = AsyncLoading()`.**
A failed save must not wipe the list. The method throws the `Failure`, the
list widget shows a snackbar, and the controller state stays `AsyncData`.
The alternative, `state = await AsyncValue.guard(...)`, is right for an
action whose result *is* the state (a login), and wrong here.
Riverpod 3 also has experimental *Mutations* for this; not used because the
API is still marked experimental.

**`retry` is switched off on the controller.**
Riverpod 3 retries a failing provider automatically (up to 10 times, 200 ms
doubling to 6.4 s). With it on, "Offline" would show an error that silently
keeps re-fetching. Here an error stays until the user taps Retry; automatic
retry belongs in the network layer where it can be limited to idempotent
requests (f04).

**The notifier is looked up at tap time.**
Since Riverpod 3 a notifier is recreated whenever its provider rebuilds. A
tear-off `ref.read(provider.notifier).recordShelfPrice` captured in `build`
can outlive its notifier after a refresh. The closure re-reads it per tap.

**`priceApiProvider` throws unless overridden.**
There is no sensible default API client, so the provider says so loudly. The
composition root (`lesson.dart`) and the tests supply one through
`overrides`. The alternative, a default that builds the real client, is fine
once one exists.

**The selected aisle is `setState`, not a provider.**
It is read by one widget and lost when the page closes. Putting it in a
provider would make it global for no reader.

**No code generation yet.**
`@riverpod` generates these same providers. Reading the hand-written form
first means the generated code will have nothing unexplained in it. Career-OS
lists codegen as "should", so it gets its own short lesson.

## What autoDispose costs

Switch Dairy → Bakery → Dairy in the demo: Dairy loads again, because its
controller was destroyed when nothing watched it. That is the trade: no stale
memory, but a refetch. `ref.keepAlive()` after a successful load, or a cache
in the repository, is the fix when the refetch is too expensive. Deciding
where the cache lives is an architecture question, not a Riverpod one.

## When Riverpod is the wrong choice

- State used by one widget: `setState`.
- A team already fluent in another solution, with no pain to fix.
- The cost: a global graph you must learn to read, and lifetime rules
  (`autoDispose`, notifier recreation, retry) that are invisible in the code
  unless you know them. This lesson exists to make them visible.

## Interview phrasing

"AsyncValue is a sealed type with three classes, but loading is also a flag:
during a refresh it stays AsyncData with isLoading true, and a failed refresh
is an AsyncError that still carries the previous value. So I pattern-match on
whether there is a value first, which keeps stale data on screen instead of
flashing a spinner or an error page."
