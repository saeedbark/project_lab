import 'package:flutter/foundation.dart';

import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository.dart';

/// What the screen can be showing. One object, three shapes: the screen
/// cannot be "loading and failed" at once, as it could with three fields.
sealed class AuditViewState {
  const AuditViewState();
}

final class AuditLoading extends AuditViewState {
  const AuditLoading();
}

final class AuditLoaded extends AuditViewState {
  const AuditLoaded(this.entries);

  final List<AuditEntry> entries;
}

final class AuditFailed extends AuditViewState {
  const AuditFailed(this.failure);

  final Failure failure;
}

/// Presentation logic with no state-management package: a [ChangeNotifier]
/// that receives its repository through the constructor.
///
/// Everything Riverpod does for us in the other lesson is written out by
/// hand here: the state type, stale-response protection, and the
/// "am I still alive?" check after every await.
class AuditViewModel extends ChangeNotifier {
  AuditViewModel({
    required this._repository,
    required this._aisle,
    this.trace = noTrace,
  });

  final PriceAuditRepository _repository;
  final Trace trace;

  String _aisle;
  String get aisle => _aisle;

  AuditViewState _state = const AuditLoading();
  AuditViewState get state => _state;

  /// Incremented per load; a response whose id is no longer current belongs
  /// to an aisle the user has already left and must be dropped.
  int _loadId = 0;
  bool _disposed = false;

  Future<void> load() async {
    final loadId = ++_loadId;
    _emit(const AuditLoading());
    try {
      final entries = await _repository.loadAisle(_aisle);
      if (_isStale(loadId)) return;
      _emit(AuditLoaded(entries));
    } on Failure catch (failure) {
      if (_isStale(loadId)) return;
      _emit(AuditFailed(failure));
    }
  }

  Future<void> selectAisle(String aisle) async {
    if (aisle == _aisle) return;
    _aisle = aisle;
    await load();
  }

  /// Throws a [Failure] if the save fails; the list is left untouched.
  Future<void> recordShelfPrice(String barcode, Price shelfPrice) async {
    final saved = await _repository.recordShelfPrice(
      barcode: barcode,
      shelfPrice: shelfPrice,
    );
    final current = _state;
    if (_disposed || current is! AuditLoaded) return;
    _emit(
      AuditLoaded([
        for (final entry in current.entries)
          if (entry.barcode == saved.barcode) saved else entry,
      ]),
    );
  }

  bool _isStale(int loadId) {
    final stale = _disposed || loadId != _loadId;
    if (stale) trace(TraceLayer.state, 'dropped a stale response');
    return stale;
  }

  void _emit(AuditViewState state) {
    _state = state;
    trace(TraceLayer.state, 'state = ${state.runtimeType}');
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    trace(TraceLayer.state, 'view model disposed');
    super.dispose();
  }
}
