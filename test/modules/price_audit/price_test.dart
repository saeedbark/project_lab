import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/modules/price_audit/models/price.dart';

void main() {
  group('Price.tryParse', () {
    test('accepts whole numbers and one or two decimals', () {
      expect(Price.tryParse('12'), const Price(1200));
      expect(Price.tryParse('12.5'), const Price(1250));
      expect(Price.tryParse(' 12.05 '), const Price(1205));
    });

    test('rejects anything that is not a plain positive decimal', () {
      for (final input in ['', 'abc', '-3', '1.234', '1,50', '.5']) {
        expect(Price.tryParse(input), isNull, reason: '"$input"');
      }
    });
  });

  test('format always shows two decimals and keeps the sign', () {
    expect(const Price(1250).format(), '12.50');
    expect(const Price(5).format(), '0.05');
    expect(const Price(-150).format(), '-1.50');
  });
}
