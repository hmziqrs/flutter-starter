import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';

void main() {
  group('BrandMaterialRecipe.fromMap', () {
    test('round-trips a full document', () {
      final source = brandMaterials.first;
      final parsed = BrandMaterialRecipe.fromMap(source.toMap());
      expect(parsed, source);
    });

    test('accepts the hmziq-material-v2 wrapper shape', () {
      final source = brandMaterials.first;
      final parsed = BrandMaterialRecipe.fromMap(<String, Object?>{
        'schema': 'hmziq-material-v2',
        'name': source.name,
        'recipe': source.toMap(),
      });
      expect(parsed, source);
    });

    test('rejects a foreign schema marker', () {
      expect(
        () => BrandMaterialRecipe.fromMap(<String, Object?>{
          'schema': 'hmziq-material-v1',
          'recipe': brandMaterials.first.toMap(),
        }),
        throwsArgumentError,
      );
    });

    test('clamps out-of-range numbers and rounds integral fields', () {
      final parsed = BrandMaterialRecipe.fromMap(const <String, Object?>{
        'id': 'x',
        'a': <String, Object?>{'mode': 99, 'scale': 10, 'detail': 0, 'seed': 17.6, 'warp': -3},
        'b': <String, Object?>{'mode': -2},
        'mix': 5,
        'blend': 9.6,
        'exposure': -4,
        'saturation': 9,
        'relief': 99,
        'lightAngle': 10,
        'roughness': 3,
        'vignette': -2,
        'grain': 42,
        'lightIntensity': 7,
        'zoom': 0.01,
        'offsetX': -500,
        'offsetY': 900,
        'speed': 0,
        'time': 400,
      });
      expect(parsed.a.mode, 29);
      expect(parsed.a.scale, 4);
      expect(parsed.a.detail, 2);
      // seed rounds after clamping, like the catalog normalizer.
      expect(parsed.a.seed, 18);
      expect(parsed.a.warp, 0);
      expect(parsed.b.mode, 0);
      expect(parsed.mix, 1);
      expect(parsed.blend, 5);
      expect(parsed.exposure, -1);
      expect(parsed.saturation, 1.6);
      expect(parsed.relief, 2.5);
      expect(parsed.lightAngle, closeTo(3.141592653589793, 0.000001));
      expect(parsed.roughness, 1);
      expect(parsed.vignette, 0);
      expect(parsed.grain, 1);
      expect(parsed.lightIntensity, 1);
      expect(parsed.zoom, 0.25);
      expect(parsed.offsetX, -100);
      expect(parsed.offsetY, 100);
      expect(parsed.speed, 0.25);
      expect(parsed.time, 60);
    });

    test('keeps unspecified values at their defaults', () {
      const fallback = BrandMaterialRecipe();
      final parsed = BrandMaterialRecipe.fromMap(const <String, Object?>{'id': 'partial'});
      expect(parsed.id, 'partial');
      expect(parsed.a, fallback.a);
      expect(parsed.b, fallback.b);
      expect(parsed.palette, fallback.palette);
      expect(parsed.mix, fallback.mix);
    });

    test('clips id and name to 80 characters', () {
      final long = 'x' * 200;
      final parsed = BrandMaterialRecipe.fromMap(<String, Object?>{'id': long, 'name': long});
      expect(parsed.id.length, 80);
      expect(parsed.name.length, 80);
    });

    test('rejects a palette that is not three six-digit hex colors', () {
      const badPalettes = <Object?>[
        <String>['#000000', '#111111'],
        <String>['#000000', '#111111', '#222222', '#333333'],
        <String>['#000000', 'nope', '#222222'],
        'not-a-list',
      ];
      for (final bad in badPalettes) {
        expect(
          () => BrandMaterialRecipe.fromMap(<String, Object?>{
            'id': 'x',
            'palette': bad,
          }),
          throwsArgumentError,
          reason: '$bad must be rejected',
        );
      }
    });

    test('rejects a non-object payload', () {
      expect(() => BrandMaterialRecipe.fromMap(42), throwsArgumentError);
    });
  });

  group('BrandMaterialLayer', () {
    test('fromMap falls back per key and clamps', () {
      const fallback = BrandMaterialLayer();
      final layer = BrandMaterialLayer.fromMap(const <String, Object?>{
        'mode': 7,
        'density': 'fast',
      });
      expect(layer.mode, 7);
      expect(layer.density, fallback.density);
      expect(layer.scale, fallback.scale);
    });

    test('clamped rounds mode, detail and seed', () {
      final layer = BrandMaterialLayer.fromMap(const <String, Object?>{
        'mode': 4.6,
        'detail': 3.5,
        'seed': 18.5,
      });
      expect(layer.mode, 5);
      expect(layer.detail, 4);
      expect(layer.seed, 19);
    });

    test('equality covers every field', () {
      const layer = BrandMaterialLayer(mode: 3);
      expect(layer, const BrandMaterialLayer(mode: 3));
      expect(layer, isNot(const BrandMaterialLayer(mode: 4)));
      expect(layer.copyWith(grain: 0.1).grain, 0.1);
    });
  });

  group('BrandMaterialPalette', () {
    test('parses hex triplets case-insensitively', () {
      final palette = BrandMaterialPalette.parse(const <String>['#160E0A', '#c75720', '#FfE1B1']);
      expect(palette.dark.toARGB32(), 0xFF160E0A);
      expect(palette.mid.toARGB32(), 0xFFC75720);
      expect(palette.bright.toARGB32(), 0xFFFFE1B1);
      expect(palette.toMap(), <String>['#160e0a', '#c75720', '#ffe1b1']);
    });
  });
}
