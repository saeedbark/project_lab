import 'package:flutter/material.dart';
import 'package:project_lab/src/core/theme/theme.dart';
import 'package:project_lab/src/core/theme/theme_mode_scope.dart';
import 'package:project_lab/src/modules/lab/models/lesson.dart';
import 'package:project_lab/src/modules/lab/pages/home_page.dart';

/// Root of the widget tree. Wiring only: themes and the first page.
class LabApp extends StatefulWidget {
  const LabApp({super.key, required this.lessons});

  final List<Lesson> lessons;

  @override
  State<LabApp> createState() => _LabAppState();
}

class _LabAppState extends State<LabApp> {
  // Dark by default; the app-bar button switches it for the session.
  final _themeMode = ValueNotifier(ThemeMode.dark);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The scope sits above MaterialApp so every route can reach it.
    return ThemeModeScope(
      notifier: _themeMode,
      child: ValueListenableBuilder(
        valueListenable: _themeMode,
        builder: (context, themeMode, _) => MaterialApp(
          title: 'Project Lab',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: HomePage(lessons: widget.lessons),
        ),
      ),
    );
  }
}
