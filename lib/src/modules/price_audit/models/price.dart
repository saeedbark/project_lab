/// An amount of money in minor units (1250 == "12.50").
///
/// An extension type: at runtime this *is* an `int`, so it costs nothing, but
/// at compile time a [Price] cannot be passed where a quantity or an id is
/// expected. Minor units avoid the rounding errors of `double`.
extension type const Price(int minorUnits) {
  /// Parses "12", "12.5" or "12.50". Returns null for anything else.
  static Price? tryParse(String input) {
    final match = _decimal.firstMatch(input.trim());
    if (match == null) return null;
    final whole = int.parse(match[1]!);
    final fraction = int.parse((match[2] ?? '').padRight(2, '0'));
    return Price(whole * 100 + fraction);
  }

  static final _decimal = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$');

  Price operator -(Price other) => Price(minorUnits - other.minorUnits);

  String format() {
    final sign = minorUnits < 0 ? '-' : '';
    final abs = minorUnits.abs();
    return '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
  }
}
