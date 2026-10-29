import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/logo_square.dart';

final Finder _square = find.descendant(
  of: find.byType(LogoSquare),
  matching: find.byType(ColoredBox),
);

void main() {
  group('LogoSquare', () {
    testWidgets('sizes in em of the surrounding text at 0.36', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const DefaultTextStyle(
            style: TextStyle(fontSize: 25),
            child: LogoSquare(),
          ),
        ),
      );

      final box = tester.widget<SizedBox>(
        find.ancestor(of: _square, matching: find.byType(SizedBox)).first,
      );
      expect(box.width, closeTo(25 * 0.36, 0.001));
      expect(box.height, closeTo(25 * 0.36, 0.001));
    });

    testWidgets('keeps the bright mark-square orange in both modes', (tester) async {
      await tester.pumpWidget(
        _harness(child: const LogoSquare()),
      );
      expect(tester.widget<ColoredBox>(_square).color, AppBrandColors.light.markSquare);

      await tester.pumpWidget(
        _harness(brightness: Brightness.dark, child: const LogoSquare()),
      );
      expect(tester.widget<ColoredBox>(_square).color, AppBrandColors.dark.markSquare);
    });

    testWidgets('is decorative', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const DefaultTextStyle(
            style: TextStyle(fontSize: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('freeoxide'),
                LogoSquare(),
              ],
            ),
          ),
        ),
      );

      // The square sits inside an ExcludeSemantics, so the logo carries no
      // semantics of its own.
      expect(
        find.ancestor(of: _square, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
    });
  });
}

Widget _harness({required Widget child, Brightness brightness = Brightness.light}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
