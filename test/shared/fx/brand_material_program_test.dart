import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/fx/shaders/brand_material_program.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';

void main() {
  test('brand_material.frag compiles as a Flutter fragment program', () async {
    final program = await FragmentProgram.fromAsset(brandMaterialShaderAsset);
    final shader = program.fragmentShader();
    // One full uniform fill across every documented slot, proving the shader
    // accepts the 64-float layout the Dart side packs.
    for (var i = 0; i < 64; i++) {
      shader.setFloat(i, 0);
    }
  });

  group('brandMaterialUniforms', () {
    final recipe = brandMaterials.first;

    // Float32 storage rounds decimals like 0.28; compare within f32 epsilon.
    void expectNear(List<double> uniforms, int slot, double value) {
      expect(uniforms[slot], closeTo(value, 0.000001), reason: 'slot $slot');
    }

    test('packs the struct order of the WGSL Params block', () {
      final uniforms = brandMaterialUniforms(
        recipe: recipe,
        width: 320,
        height: 200,
        time: 12.5,
      );
      expect(uniforms.length, 64);
      // viewport: width, height, time, output.
      expectNear(uniforms, 0, 320);
      expectNear(uniforms, 1, 200);
      expectNear(uniforms, 2, 12.5);
      expectNear(uniforms, 3, 0);
      // mixing: mix, blend, exposure, saturation.
      expectNear(uniforms, 4, recipe.mix);
      expectNear(uniforms, 5, recipe.blend.toDouble());
      expectNear(uniforms, 6, recipe.exposure);
      expectNear(uniforms, 7, recipe.saturation);
      // light: relief, lightAngle, vignette, roughness.
      expectNear(uniforms, 8, recipe.relief);
      expectNear(uniforms, 9, recipe.lightAngle);
      expectNear(uniforms, 10, recipe.vignette);
      expectNear(uniforms, 11, recipe.roughness);
      // view: offsetX, offsetY, zoom, compare.
      expectNear(uniforms, 24, recipe.offsetX);
      expectNear(uniforms, 25, recipe.offsetY);
      expectNear(uniforms, 26, recipe.zoom);
      expectNear(uniforms, 27, -1);
      // finish: grain, lightIntensity, maskMode.
      expectNear(uniforms, 28, recipe.grain);
      expectNear(uniforms, 29, recipe.lightIntensity);
      expectNear(uniforms, 30, 0);
      // layer a: shape (mode, scale, warp, detail), surface, tone.
      expectNear(uniforms, 32, recipe.a.mode.toDouble());
      expectNear(uniforms, 33, recipe.a.scale);
      expectNear(uniforms, 34, recipe.a.warp);
      expectNear(uniforms, 35, recipe.a.detail.toDouble());
      expectNear(uniforms, 36, recipe.a.angle);
      expectNear(uniforms, 37, recipe.a.seed);
      expectNear(uniforms, 38, recipe.a.density);
      expectNear(uniforms, 39, recipe.a.speed);
      expectNear(uniforms, 40, recipe.a.contrast);
      expectNear(uniforms, 41, recipe.a.balance);
      expectNear(uniforms, 42, recipe.a.grain);
      // layer b starts at 44.
      expectNear(uniforms, 44, recipe.b.mode.toDouble());
      expectNear(uniforms, 55, 0);
      // text extension: amount, tintAmount, tint rgb.
      expectNear(uniforms, 56, 1);
      expectNear(uniforms, 57, 0);
      expectNear(uniforms, 60, recipe.palette.bright.r);
      expectNear(uniforms, 61, recipe.palette.bright.g);
      expectNear(uniforms, 62, recipe.palette.bright.b);
    });

    test('mask mode sets slot 30 and carries tint', () {
      const tint = Color(0xFF123456);
      final uniforms = brandMaterialUniforms(
        recipe: recipe,
        width: 10,
        height: 10,
        time: 0,
        mask: true,
        amount: 0.75,
        tintAmount: 0.25,
        tint: tint,
      );
      expect(uniforms[30], 1);
      expect(uniforms[56], closeTo(0.75, 0.000001));
      expect(uniforms[57], closeTo(0.25, 0.000001));
      expect(uniforms[60], closeTo(tint.r, 0.001));
      expect(uniforms[61], closeTo(tint.g, 0.001));
      expect(uniforms[62], closeTo(tint.b, 0.001));
    });

    test('output and compare land in their viewport/view slots', () {
      final uniforms = brandMaterialUniforms(
        recipe: recipe,
        width: 10,
        height: 10,
        time: 0,
        output: 2,
        compare: 0.4,
      );
      expect(uniforms[3], 2);
      expect(uniforms[27], closeTo(0.4, 0.000001));
    });
  });

  test('every approved material sits inside schema range already', () {
    for (final material in brandMaterials) {
      expect(material, material.clamped(), reason: '${material.id} must be pre-normalized');
    }
  });
}
