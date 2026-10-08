import 'package:flutter/material.dart';
import 'package:project_lab/src/core/utils/trace.dart';

/// Light and dark themes, generated from one seed colour.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF2E5E4E);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: .fromSeed(seedColor: seed, brightness: brightness),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        isDense: true,
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      extensions: [dark ? LabColors.dark : LabColors.light],
    );
  }
}

/// Colours the seed scheme has no role for: one per trace layer, and "ok".
///
/// A [ThemeExtension] rather than constants, so a widget asks the theme and
/// gets the variant that is readable on the current background.
class LabColors extends ThemeExtension<LabColors> {
  const LabColors({
    required this.ui,
    required this.state,
    required this.repository,
    required this.dataSource,
    required this.success,
  });

  static const light = LabColors(
    ui: Color(0xFF3949AB),
    state: Color(0xFF00796B),
    repository: Color(0xFFD84315),
    dataSource: Color(0xFF6D4C41),
    success: Color(0xFF2E7D32),
  );

  static const dark = LabColors(
    ui: Color(0xFF9FA8DA),
    state: Color(0xFF80CBC4),
    repository: Color(0xFFFFAB91),
    dataSource: Color(0xFFBCAAA4),
    success: Color(0xFF81C784),
  );

  final Color ui;
  final Color state;
  final Color repository;
  final Color dataSource;
  final Color success;

  /// Falls back on brightness so a widget also works under a bare
  /// `MaterialApp`, as in widget tests.
  static LabColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<LabColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  Color layer(TraceLayer layer) => switch (layer) {
    TraceLayer.ui => ui,
    TraceLayer.state => state,
    TraceLayer.repository => repository,
    TraceLayer.dataSource => dataSource,
  };

  @override
  LabColors copyWith({
    Color? ui,
    Color? state,
    Color? repository,
    Color? dataSource,
    Color? success,
  }) => LabColors(
    ui: ui ?? this.ui,
    state: state ?? this.state,
    repository: repository ?? this.repository,
    dataSource: dataSource ?? this.dataSource,
    success: success ?? this.success,
  );

  @override
  LabColors lerp(LabColors? other, double t) {
    if (other == null) return this;
    return LabColors(
      ui: Color.lerp(ui, other.ui, t)!,
      state: Color.lerp(state, other.state, t)!,
      repository: Color.lerp(repository, other.repository, t)!,
      dataSource: Color.lerp(dataSource, other.dataSource, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
