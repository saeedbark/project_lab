import 'dart:async';

import 'package:project_lab/src/core/errors/failure.dart';
import 'package:project_lab/src/core/utils/trace.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry_dto.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';
import 'package:project_lab/src/modules/price_audit/services/price_api.dart';
import 'package:project_lab/src/modules/price_audit/services/price_audit_repository.dart';

final class PriceAuditRepositoryImpl implements PriceAuditRepository {
  PriceAuditRepositoryImpl({
    required this._api,
    this.trace = noTrace,
    this.timeout = const Duration(seconds: 3),
  });

  final PriceApi _api;
  final Trace trace;
  final Duration timeout;

  @override
  Future<List<AuditEntry>> loadAisle(String aisle) {
    return _guard('loadAisle($aisle)', () async {
      final rows = await _api.fetchAisle(aisle).timeout(timeout);
      return [for (final row in rows) AuditEntryDto.fromJson(row).toDomain()];
    });
  }

  @override
  Future<AuditEntry> recordShelfPrice({
    required String barcode,
    required Price shelfPrice,
  }) {
    return _guard(
      'recordShelfPrice($barcode, ${shelfPrice.format()})',
      () async {
        final row = await _api
            .putShelfPrice(barcode, shelfPrice.format())
            .timeout(timeout);
        return AuditEntryDto.fromJson(row).toDomain();
      },
    );
  }

  /// The single place where transport errors become [Failure]s.
  ///
  /// Catches `Exception` only: an `Error` (a bug, e.g. a failed cast) must
  /// crash loudly instead of being dressed up as a network problem.
  Future<T> _guard<T>(String call, Future<T> Function() body) async {
    trace(TraceLayer.repository, call);
    try {
      final result = await body();
      trace(TraceLayer.repository, '$call → mapped DTO to domain');
      return result;
    } on Exception catch (error) {
      final failure = switch (error) {
        ConnectionException() => const OfflineFailure(),
        TimeoutException() => const TimeoutFailure(),
        ApiException(:final statusCode) => ServerFailure(statusCode),
        _ => UnexpectedFailure(error),
      };
      trace(
        TraceLayer.repository,
        '$call → ${error.runtimeType} mapped to ${failure.runtimeType}',
      );
      throw failure;
    }
  }
}
