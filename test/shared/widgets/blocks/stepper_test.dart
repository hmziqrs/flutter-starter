import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/stepper.dart';

void main() {
  group('AppStepper', () {
    for (final brightness in Brightness.values) {
      final isDark = brightness == Brightness.dark;
      final theme = isDark ? generated.darkTheme : generated.lightTheme;
      final brand = theme.brand;

      testWidgets('fills done steps with primary and turns their line primary at $brightness', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(
            brightness: brightness,
            child: const AppStepper(
              steps: _steps,
              currentStep: 1,
            ),
          ),
        );

        final rings = _rings(tester);
        expect(rings, hasLength(3));

        // Step 0 is done: solid primary fill, ring in primary, number on it.
        final done = rings[0].decoration! as ShapeDecoration;
        expect(done.color, brand.oxide);
        expect((done.shape as CircleBorder).side.color, brand.oxide);
        expect(_textColor(tester, '1'), brand.onOrange);

        // The line below a done step turns primary.
        final connectors = _connectors(tester);
        expect(connectors, hasLength(2));
        expect(connectors[0].color, brand.oxide);

        // Step 1 is current: hollow primary ring, primary number.
        final current = rings[1].decoration! as ShapeDecoration;
        expect(current.color!.a, 0, reason: 'hollow means no fill');
        expect((current.shape as CircleBorder).side.color, brand.oxide);
        expect(_textColor(tester, '2'), brand.oxide);

        // Step 2 is upcoming: muted ring on the border color.
        final upcoming = rings[2].decoration! as ShapeDecoration;
        expect((upcoming.shape as CircleBorder).side.color, theme.colors.border);
        expect(_textColor(tester, '3'), theme.colors.mutedForeground);
        expect(connectors[1].color, theme.colors.border);
      });
    }

    testWidgets('rings keep the 1.75 brand border and 36dp size', (tester) async {
      await tester.pumpWidget(_harness(child: const AppStepper(steps: _steps, currentStep: 0)));
      final ring = _rings(tester).first;
      final ringSide = ((ring.decoration! as ShapeDecoration).shape as CircleBorder).side;
      expect(ringSide.width, 1.75);
      expect(ring.constraints!.minWidth, 36);
    });

    testWidgets('reports taps for the activated step', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(
        _harness(
          child: AppStepper(
            steps: _steps,
            currentStep: 0,
            onStepTap: (index) => tapped = index,
          ),
        ),
      );
      await tester.tap(find.text('3'));
      expect(tapped, 2);
    });
  });
}

const _steps = <AppStepperStep>[
  (label: 'Install the CLI', description: 'One command.'),
  (label: 'Sign in', description: null),
  (label: 'Create your first project', description: null),
];

List<Container> _rings(WidgetTester tester) => tester
    .widgetList<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is ShapeDecoration &&
            (widget.decoration! as ShapeDecoration).shape is CircleBorder &&
            widget.constraints?.minWidth == 36,
      ),
    )
    .toList();

List<Container> _connectors(WidgetTester tester) => tester
    .widgetList<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.minWidth == 1 &&
            widget.constraints?.minHeight == 20,
      ),
    )
    .toList();

Color _textColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

Widget _harness({required Widget child, Brightness brightness = Brightness.light}) {
  final theme = brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: theme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
