import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_material_text.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/fx/shaders/brand_shimmer.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  group('BrandMaterialSurface', () {
    testWidgets('renders a still frame from an explicit time', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 96,
            height: 48,
            child: BrandMaterialSurface(recipe: materialFor('test'), time: 12.5),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('animates without error and honors the pause hook', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 96,
            height: 48,
            child: BrandMaterialSurface(recipe: materialFor('copper'), paused: true),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints non-uniform material pixels', (tester) async {
      const key = ValueKey('material-pixels');
      await tester.pumpWidget(
        _harness(
          child: const RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 64,
              height: 64,
              child: BrandMaterialSurface(recipe: BrandMaterialRecipe(id: 'x'), time: 2),
            ),
          ),
        ),
      );
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final distinct = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
        image.dispose();
        final pixels = data!.buffer.asUint32List();
        return pixels.where((pixel) => pixel != pixels.first).length;
      });
      expect(distinct, greaterThan(0), reason: 'the material shader must vary across the quad');
      expect(tester.takeException(), isNull);
    });
  });

  group('BrandMaterialText', () {
    testWidgets('fills the text with a material frame', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const BrandMaterialText(
            text: 'Make it\nmaterial.',
            fontSize: 24,
            time: 4,
            animated: false,
          ),
        ),
      );
      await tester.pump();
      expect(tester.widget<Text>(find.text('Make it\nmaterial.')), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pinned seed changes the recipe seeds, not the id', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const BrandMaterialText(text: 'x', seed: 9, animated: false, fontSize: 12),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('BrandShimmer', () {
    testWidgets('sweeps a highlight across the letters', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const BrandShimmer(
            duration: Duration(milliseconds: 400),
            rest: Duration(milliseconds: 400),
            child: Text('freeoxide'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ShaderMask), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders plain letters under reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1,
            child: Builder(
              builder: (context) => FTheme(
                data: generated.lightTheme,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: const Center(
                    child: BrandShimmer(child: Text('freeoxide')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.text('freeoxide'), findsOneWidget);
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
