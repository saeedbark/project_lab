import 'package:project_lab/src/modules/price_audit/models/price.dart';

/// One product on a shelf, and what the auditor found on its label.
///
/// [shelfPrice] is null until the auditor has checked the label.
final class AuditEntry {
  const AuditEntry({
    required this.barcode,
    required this.name,
    required this.aisle,
    required this.systemPrice,
    this.shelfPrice,
  });

  final String barcode;
  final String name;
  final String aisle;
  final Price systemPrice;
  final Price? shelfPrice;

  /// Derived, never stored: there is no way to build an entry whose status
  /// disagrees with its prices.
  AuditStatus get status => switch (shelfPrice) {
    null => const Pending(),
    final shelf when shelf == systemPrice => const Match(),
    final shelf => Mismatch(shelf - systemPrice),
  };

  @override
  bool operator ==(Object other) =>
      other is AuditEntry &&
      other.barcode == barcode &&
      other.name == name &&
      other.aisle == aisle &&
      other.systemPrice == systemPrice &&
      other.shelfPrice == shelfPrice;

  @override
  int get hashCode =>
      Object.hash(barcode, name, aisle, systemPrice, shelfPrice);

  @override
  String toString() => 'AuditEntry($barcode, shelf: $shelfPrice)';
}

sealed class AuditStatus {
  const AuditStatus();
}

final class Pending extends AuditStatus {
  const Pending();
}

final class Match extends AuditStatus {
  const Match();
}

final class Mismatch extends AuditStatus {
  const Mismatch(this.difference);

  /// Shelf price minus system price: positive means the label overcharges.
  final Price difference;
}
