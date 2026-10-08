import 'package:flutter/material.dart';

/// Makes the app's [ThemeMode] readable and changeable from any page.
///
/// An [InheritedNotifier] over a plain [ValueNotifier]: one value, read in
/// two places, so it does not need a state-management package. The lessons
/// create their own `ProviderScope`, and the shell stays independent of it.
class ThemeModeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeModeScope({
    super.key,
    required ValueNotifier<ThemeMode> super.notifier,
    required super.child,
  });

  static ValueNotifier<ThemeMode> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeModeScope>()!.notifier!;
}

/// Switches between dark and light. Meant for an app bar's `actions`.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = ThemeModeScope.of(context);
    final dark = mode.value == ThemeMode.dark;
    return IconButton(
      tooltip: dark ? 'Light mode' : 'Dark mode',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => mode.value = dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
