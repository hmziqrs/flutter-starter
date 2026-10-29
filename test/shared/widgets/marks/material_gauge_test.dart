import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/material_gauge.dart';

void main() {
  group('MaterialGauge', () {
    testWidgets('sweeps a share of the ring over the track', (tester) async {
      await tester.pumpWidget(
        _harness(child: MaterialGauge(recipe: materialFor('copper'), value: 0.68)),
      );

      expect(tester.getSize(find.byType(MaterialGauge)), const Size(72, 72));
      expect(find.byType(BrandMaterialSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a whole number above 1 splits the ring into segments', (tester) async {
      await tester.pumpWidget(
        _harness(child: MaterialGauge(recipe: materialFor('copper'), value: 5)),
      );

      expect(find.byType(BrandMaterialSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('holds still at zero and the full ring at one', (tester) async {
      for (final value in <double>[0, 1]) {
        await tester.pumpWidget(
          _harness(
            child: MaterialGauge(recipe: materialFor('copper'), value: value),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'value $value');
      }
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
