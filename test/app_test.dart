import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_lab/src/app.dart';

void main() {
  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold))).brightness;

  testWidgets('starts in dark mode and the app-bar button switches it', (
    tester,
  ) async {
    await tester.pumpWidget(const LabApp(lessons: []));
    expect(brightness(tester), Brightness.dark);

    await tester.tap(find.byTooltip('Light mode'));
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Dark mode'));
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.dark);
  });
}
