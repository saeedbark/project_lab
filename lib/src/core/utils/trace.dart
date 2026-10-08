/// The layer an event was emitted from. The lab's trace panel colors by it.
enum TraceLayer { ui, state, repository, dataSource }

/// A sink for "what just happened" events.
///
/// It is a plain function type so that feature code depends on nothing from
/// the lab: production code would pass [noTrace] or a logger.
typedef Trace = void Function(TraceLayer layer, String message);

void noTrace(TraceLayer layer, String message) {}
