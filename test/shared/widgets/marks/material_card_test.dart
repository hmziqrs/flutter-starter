import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/material_card.dart';

void main() {
  group('MaterialCard', () {
    testWidgets('crowns the card with a 16:10 material band and a hairline', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 320,
            child: MaterialCard(recipe: materialFor('copper'), child: const Text('Cover')),
          ),
        ),
      );

      await tester.pump();
      // The kit's cover band: aspect 16/10 of the card's width.
      final band = tester.widget<SizedBox>(
        find.byWidgetPredicate((widget) => widget is SizedBox && widget.height == 320 * 10 / 16),
      );
      expect(band, isNotNull);
      expect(
        find.descendant(
          of: find.byType(MaterialCard),
          matching: find.byType(BrandMaterialSurface),
        ),
        findsOneWidget,
      );
      // The kit's `ring-1 ring-foreground/10`.
      final outline =
          tester
                  .widget<Container>(
                    find.byWidgetPredicate(
                      (widget) =>
                          widget is Container && widget.foregroundDecoration is ShapeDecoration,
                    ),
                  )
                  .foregroundDecoration!
              as ShapeDecoration;
      expect(
        (outline.shape as RoundedSuperellipseBorder).side.color,
        generated.lightTheme.colors.foreground.withValues(alpha: 0.1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('an explicit band extent overrides the proportion', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 320,
            child: MaterialCard(
              recipe: materialFor('copper'),
              bandExtent: 72,
              child: const Text('Compact'),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) => widget is SizedBox && widget.height == 72),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
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
