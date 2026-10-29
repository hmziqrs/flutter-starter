import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';

void main() {
  group('AppIconTile', () {
    testWidgets('draws a 36px outline tile with an 18px primary icon', (tester) async {
      await tester.pumpWidget(
        _harness(child: const AppIconTile(icon: FLucideIcons.inbox)),
      );
      await tester.pump();

      final colors = generated.lightTheme.colors;
      expect(tester.getSize(find.byType(AppIconTile)), const Size(36, 36));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 18);
      expect(icon.color, colors.primary);

      final decoration = _tileDecoration(tester);
      expect(decoration.color, Colors.transparent);
      final shape = decoration.shape as RoundedRectangleBorder;
      expect(shape.side.color, colors.border);
      expect(shape.side.width, generated.lightTheme.style.borderWidth);
      expect(shape.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('a tone fills the tile softly in its own color and drops the border', (
      tester,
    ) async {
      const tone = Color(0xFFCD1622);
      await tester.pumpWidget(
        _harness(
          child: const AppIconTile(
            icon: FLucideIcons.octagonAlert,
            tone: Color(0xFFCD1622),
          ),
        ),
      );
      await tester.pump();

      expect(tester.widget<Icon>(find.byType(Icon)).color, tone);
      final decoration = _tileDecoration(tester);
      // The softTone recipe: 10% fill in light, no outline.
      expect(decoration.color, tone.withValues(alpha: 0.10));
      expect((decoration.shape as RoundedRectangleBorder).side, BorderSide.none);
    });

    testWidgets('iconColor keeps the outline tile and colors only the icon', (tester) async {
      const tint = Color(0xFFCD1622);
      await tester.pumpWidget(
        _harness(
          child: const AppIconTile(icon: FLucideIcons.octagonAlert, iconColor: tint),
        ),
      );
      await tester.pump();

      expect(tester.widget<Icon>(find.byType(Icon)).color, tint);
      final colors = generated.lightTheme.colors;
      final decoration = _tileDecoration(tester);
      expect(decoration.color, Colors.transparent);
      expect((decoration.shape as RoundedRectangleBorder).side.color, colors.border);
    });

    testWidgets('scales the icon with the tile size', (tester) async {
      await tester.pumpWidget(
        _harness(child: const AppIconTile(icon: FLucideIcons.inbox, size: 48)),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(AppIconTile)), const Size(48, 48));
      expect(tester.widget<Icon>(find.byType(Icon)).size, 24);
    });
  });
}

ShapeDecoration _tileDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(AppIconTile), matching: find.byType(Container)).first,
  );
  return container.decoration! as ShapeDecoration;
}

Widget _harness({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
