# d03 · Future vs Stream

Career-OS week 1: w1t2 (the async guide, Future vs Stream), w1t6 (record 5
minutes in English: "Future vs Stream — when and why") and w1t7 (10 async
interview questions). Do w1t7 the Career-OS way: write your answers *before*
reading the "Interview phrasing" section at the end.

Same feature as f02 and f03. New: a live feed in `services/`, a
`StreamProvider` in `providers/`, and `LiveAuditPage`. Written against
Dart 3.13.4 and Riverpod 3.4.3. Every Stream behaviour stated here is pinned
in `test/modules/price_audit/live_feed_test.dart`.

**Left to you on purpose:** w1t4 asks for a hand-written Stream transformer
in dart-drills. This lesson uses `map` and `handleError` and never writes a
`StreamTransformer`. The "conflate" idea under *What pause costs* is a good
candidate for that drill.

## The difference in one table

| | `Future<T>` | `Stream<T>` |
|---|---|---|
| Values | exactly one, or one error | zero or more values and errors, then maybe done |
| Starts | when the function is called (eager) | single-subscription: on `listen` (lazy) |
| Can the caller stop it? | no: you can stop *waiting* (`timeout`), not the work | yes: `subscription.cancel()` |
| Consumed with | `await`, `then` | `await for`, `listen` |
| In Flutter | `FutureBuilder`, `FutureProvider`, `AsyncNotifier` | `StreamBuilder`, `StreamProvider`, `StreamNotifier` |

The row people forget is cancellation. f02 showed that `Future.timeout` stops
waiting while the request carries on. A stream subscription can actually be
cancelled, and in this lesson cancelling closes a socket and stops a timer.

## Same data, two shapes

`PriceApi` now has both:

- `fetchAisle` / `loadAisle`: **ask once.** The answer is the aisle at that
  moment. To see changes, ask again (Refresh in f03).
- `watchAisle`: **subscribe.** The aisle now, then again whenever it
  changes, until you cancel.

Choose a Stream when **the source pushes**: a socket, a database watch
(Firestore `snapshots()`, Supabase realtime, drift `watch()`), location,
connectivity, Bluetooth. Choose a Future when you ask a question and get one
answer, even if you ask it often.

Two common mistakes:

- A Stream that only ever emits once. That is a Future with extra steps.
- Polling dressed up as a stream: `Stream.periodic(...).asyncMap(fetch)` is
  fine, but it is still polling. Say so in a code review.

## The two kinds of stream, both in `fake_price_api.dart`

| | The feed: `watchAisle` | The bus: `_changes` |
|---|---|---|
| Kind | single-subscription `StreamController` | `StreamController.broadcast` |
| Listeners | exactly one; a second `listen` throws `StateError` | any number |
| Events nobody listens to | buffered until someone listens | dropped |
| Pause | the controller buffers (`onPause` fires) | `StreamController.broadcast` takes no `onPause`: one listener pausing does not pause the source |
| `onListen` / `onCancel` | per subscription: open / close this client's socket | first listener / last one left: start / stop repricing |

The broadcast bus explains a design detail: **every feed starts with a
snapshot.** A broadcast stream has no history, so a client that subscribes
late, or reconnects, would otherwise miss everything that happened before.
The "broadcast" test shows a late listener getting one snapshot that already
contains the change it never heard about.

**`asBroadcastStream` is the wrong fix for "two widgets want the same
feed".** It subscribes once and "will stay subscribed until this stream
ends" (the SDK's own doc). A test pins it: both listeners cancel and the
socket is still open. To share a feed in this app, two widgets watch the same
`liveAisleProvider(aisle)`. One provider means one subscription, and
`autoDispose` closes it when the last watcher leaves.

## The four controller callbacks, and who triggers each here

| Callback | Fired when | Here |
|---|---|---|
| `onListen` | the first (only) `listen` | handshake, first snapshot, subscribe to the bus |
| `onPause` | the subscriber pauses (Riverpod, `await for`) | trace only; the controller buffers by itself |
| `onResume` | it resumes | buffered snapshots are delivered |
| `onCancel` | the subscriber cancels | unsubscribe from the bus, which may stop repricing |

## The cancellation chain

Switch from Dairy to Bakery and read the trace from the top:

1. The page stops watching `liveAisleProvider('Dairy')`.
2. Riverpod's `onCancel`: no listener left, so it **pauses** the stream
   subscription (`riverpod-3.4.3/lib/src/core/element.dart`, `onCancel`).
3. The listener was removed, not hidden, so `autoDispose` disposes the
   provider, and disposal **cancels** the subscription.
4. `handleError` and `map` pass the cancel straight to the API's feed. These
   forwarding streams own no subscription of their own.
5. The feed's `onCancel` cancels its bus subscription. If it was the last
   one, head office stops repricing.

`live_audit_page_test.dart` pins that exact order. Compare a Future: once
`loadAisle` is called, nothing in the app can stop the request.

## Decisions, and what was rejected

**The feed is a `StreamController`, not an `async*` generator.**
`async*` with `yield` is the neat way to write a stream, and it was the first
draft. The problem is pinned in the last group of `live_feed_test.dart`: an
`async*` body waiting inside `await for` only notices a cancel at its next
`yield`, so `cancel()` does not complete, and the source stays subscribed,
until the source emits again. For a quiet aisle that may be never: a socket
left open for a screen that no longer exists. A controller's `onCancel` runs
at once.
`async*` is the right tool when the body produces values from its own loop
(a paginated download, a generator over a list) or the source is short-lived.
If that test ever fails, the SDK changed and the generator became viable.

**The repository uses `map` + `handleError`, not `async*` + `await for`.**
Same reason, plus laziness: a pipeline of stream methods listens to nothing
until the page does. `handleError` with a `throw` inside replaces the error
event with a `Failure`; `test:` lets `Error`s (bugs) through untouched, the
same rule `_guard` applies to Futures. Both paths share `_toFailure`.

**No `.timeout` on the stream.**
`loadAisle` times out at 3 s. `Stream.timeout` measures the gap *between
events*, and on a live feed a quiet minute is normal. Connection health
belongs to the socket (pings), not to a stream operator.

**Snapshots, not deltas.**
The feed sends the whole aisle on every change. Deltas ("milk is now 13.00")
use less bandwidth, but then the client must fetch the list, subscribe, and
apply changes in order without losing one that lands in between. That is a
real race, and getting it wrong shows a stale price. Snapshots make the first
event and every reconnect correct by construction. Deltas win for long lists
and chat-like feeds, where the list is too big to resend.

**`StreamProvider`, no notifier, and saves go to the repository.**
f03's controller patched its own state after a save. Here the page calls
`recordShelfPrice`, and the list changes when the server's echo arrives on
the feed. The state has one writer, so a save response and an echo can never
race to set it. The rejected version, `StreamNotifier` patching state after
a save, has two writers and needs an ordering rule. This is the wrong choice
when the server does not echo writes, or when the UI must update before the
server answers (optimistic updates).

**A drop ends the stream; Reconnect is `invalidate`.**
After an error event the feed closes, so the provider holds an `AsyncError`
that still carries the last snapshot (Riverpod's `copyWithPrevious`, the same
rule as f03). Reconnecting is a new subscription, and its first snapshot
includes whatever changed while the feed was down. `retry` is switched off
so you can see this. In production, Riverpod's `retry` with backoff *is*
automatic reconnection for a `StreamProvider`, and a reasonable default.

**The page never calls `listen` or uses `await for`.**
Riverpod listens (`handleStream` in `element.dart`). Without Riverpod: a
`StreamBuilder`, or `listen` in `initState` with `cancel` in `dispose`.

## `await for` versus `listen`

| | `await for` | `listen` |
|---|---|---|
| Shape | a loop inside an `async` function | callbacks, returns a `StreamSubscription` |
| While the body runs | **pauses** the subscription (pinned: the feed logs "paused") | keeps delivering |
| Leaving early | `break` / `return` cancels | `subscription.cancel()` |
| An error event | thrown out of the loop, subscription cancelled | `onError`, and the stream may continue |
| Ends when | the stream is done | never by itself; you own the subscription |

Use `await for` when the consumer is sequential and finishes: a script, a
test, an upload queue that sends one item at a time (f07). Use `listen` when
the subscription lives as long as an object with a lifecycle (a provider, a
`State`), and cancel it when that object dies.

Note the error row. The Stream API allows events after an error (the "with
listen" test shows it), so "error means the end" is this feed's contract,
written on `PriceApi.watchAisle`, not a rule of streams.

## What pause costs

Tap "Open another screen". Riverpod 3 pauses subscriptions of widgets whose
`TickerMode` is off (`flutter_riverpod-3.4.3/lib/src/core/consumer.dart`), and
a covered route has it off. The feed buffers every snapshot, and on return
delivers all of them, each one a new `AsyncData`, though only the last one
matters.

For a snapshot feed the better behaviour is to *conflate*: keep only the
latest while paused. That is a stream transformer, which is your dart-drills
exercise.

One lab detail: on a narrow window the lesson page hides the demo in an
`IndexedStack`. `IndexedStack` hides children without turning `TickerMode`
off, so there the feed keeps running. Hidden is not the same as paused.

## When a Stream is the wrong choice

- One request, one answer: a Future, even if you repeat the request.
- The UI needs the current value synchronously (`value` right now, no
  loading state): a `ValueNotifier` or provider state, fed by the stream.
- The backend cannot push: honest polling with a Future on a timer is
  clearer than a stream that pretends to be live.
- The cost of a stream is lifecycle: every `listen` is a subscription
  someone must cancel. A Future cannot leak that way.

## Interview phrasing

"A Future is one value that arrives later; a Stream is a sequence of values
over time. I return a Future when I ask a question, like loading a list, and
a Stream when the source pushes changes, like a socket or a database watch.
The practical difference is ownership: a stream subscription has to be
cancelled. So I expose it through something with a lifecycle, a
StreamProvider with autoDispose or a StreamBuilder, and cancelling it closes
the connection. Single-subscription streams are lazy and buffer; broadcast
streams have many listeners and drop events nobody is listening to, which is
why my feeds start with a snapshot."

For the w1t6 recording, five minutes is roughly: that paragraph (1 min), the
same-data-two-shapes example (1 min), single vs broadcast (1 min), cancel and
the async* trap (1 min), await for vs listen (1 min).
