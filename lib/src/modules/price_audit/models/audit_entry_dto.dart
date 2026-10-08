import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';

/// The wire shape of an audit entry.
///
/// Kept separate from [AuditEntry] so that a renamed JSON key or a changed
/// price encoding is absorbed here and never reaches the domain or the UI.
final class AuditEntryDto {
  const AuditEntryDto({
    required this.barcode,
    required this.name,
    required this.aisle,
    required this.systemPrice,
    required this.shelfPrice,
  });

  /// Throws a [FormatException] when the payload is not what we expect.
  factory AuditEntryDto.fromJson(Map<String, Object?> json) {
    return switch (json) {
      {
        'barcode': final String barcode,
        'name': final String name,
        'aisle': final String aisle,
        'system_price': final String systemPrice,
        'shelf_price': final String? shelfPrice,
      } =>
        AuditEntryDto(
          barcode: barcode,
          name: name,
          aisle: aisle,
          systemPrice: systemPrice,
          shelfPrice: shelfPrice,
        ),
      _ => throw FormatException('Unexpected audit entry payload: $json'),
    };
  }

  final String barcode;
  final String name;
  final String aisle;
  final String systemPrice;
  final String? shelfPrice;

  AuditEntry toDomain() => AuditEntry(
    barcode: barcode,
    name: name,
    aisle: aisle,
    systemPrice: _parse(systemPrice),
    shelfPrice: switch (shelfPrice) {
      null => null,
      final price => _parse(price),
    },
  );

  static Price _parse(String raw) =>
      Price.tryParse(raw) ?? (throw FormatException('Not a price: "$raw"'));
}
