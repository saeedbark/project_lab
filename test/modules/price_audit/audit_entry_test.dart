import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/modules/price_audit/models/audit_entry.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';

AuditEntry _entry({Price? shelfPrice}) => AuditEntry(
  barcode: '1',
  name: 'Milk',
  aisle: 'Dairy',
  systemPrice: const Price(1250),
  shelfPrice: shelfPrice,
);

void main() {
  test('an unchecked entry is pending', () {
    expect(_entry().status, isA<Pending>());
  });

  test('a label equal to the system price is a match', () {
    expect(_entry(shelfPrice: const Price(1250)).status, isA<Match>());
  });

  test('a mismatch reports shelf minus system', () {
    final status = _entry(shelfPrice: const Price(1300)).status;

    expect(
      status,
      isA<Mismatch>().having(
        (m) => m.difference,
        'difference',
        const Price(50),
      ),
    );
  });
}
