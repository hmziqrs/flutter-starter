import 'dart:typed_data' show Float32List;
import 'dart:ui'
    show Canvas, Color, FragmentProgram, FragmentShader, Image, Paint, PictureRecorder, Rect;

import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';

/// Where the compiled brand material program lives in the asset bundle
/// (declared under `flutter: shaders:` in pubspec.yaml).
const String brandMaterialShaderAsset = 'assets/shaders/brand_material.frag';

/// The compiled brand material fragment program, loaded once and shared by
/// every surface and text that renders a material.
///
/// The shader always declares one sampler (the text-mask mode reads the child
/// snapshot through it), so every produced shader binds [_blankSampler] when
/// no real input exists — keeps Skia and Impeller agreement on sampler state.
final class BrandMaterialProgram {
  BrandMaterialProgram._(this._program, this._blankSampler);

  static BrandMaterialProgram? _instance;

  /// Loads (and memoizes) the compiled shader program.
  static Future<BrandMaterialProgram> load() async {
    final existing = _instance;
    if (existing != null) {
      return existing;
    }
    final program = await FragmentProgram.fromAsset(brandMaterialShaderAsset);
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = const Color(0xFF000000),
    );
    final blank = recorder.endRecording().toImageSync(1, 1);
    return _instance = BrandMaterialProgram._(program, blank);
  }

  final FragmentProgram _program;
  final Image _blankSampler;

  /// Builds a fresh shader bound to the compiled program. The caller owns it
  /// and must dispose it after painting.
  FragmentShader newShader() => _program.fragmentShader();

  /// Binds the no-op sampler for material modes that read no input texture.
  void bindBlankSampler(FragmentShader shader) => shader.setImageSampler(0, _blankSampler);
}

/// Packs a recipe into the shader's 64 `setFloat` slots, mirroring the WGSL
/// `Params` struct order:
///
/// | slots | struct   | values |
/// |-------|----------|--------|
/// | 0–3   | viewport | width, height, time, output |
/// | 4–7   | mixing   | mix, blend, exposure, saturation |
/// | 8–11  | light    | relief, lightAngle, vignette, roughness |
/// | 12–15 | dark     | rgb, 1 |
/// | 16–19 | mid      | rgb, 1 |
/// | 20–23 | bright   | rgb, 1 |
/// | 24–27 | view     | offsetX, offsetY, zoom, compare |
/// | 28–31 | finish   | grain, lightIntensity, maskMode, 0 |
/// | 32–43 | layer a  | shape, surface, tone |
/// | 44–55 | layer b  | shape, surface, tone |
/// | 56–63 | text     | amount, tintAmount, 0, 0, tint rgb, 0 |
///
/// `output` selects 0 = lit material, 1 = raw height, 2 = normals, 3+ = tone.
/// `compare` (−1 to disable) draws layer a to the left of that x fraction.
/// `mask` turns on the text-mask mode, where the shader gates its output on
/// the alpha of the sampler in slot 0.
Float32List brandMaterialUniforms({
  required BrandMaterialRecipe recipe,
  required double width,
  required double height,
  required double time,
  int output = 0,
  double compare = -1,
  bool mask = false,
  double amount = 1,
  double tintAmount = 0,
  Color? tint,
}) {
  final uniforms = Float32List(64);
  var i = 0;
  void vec4(double a, double b, double c, double d) {
    uniforms[i++] = a;
    uniforms[i++] = b;
    uniforms[i++] = c;
    uniforms[i++] = d;
  }

  void layer(BrandMaterialLayer layer) {
    vec4(
      layer.mode.toDouble(),
      layer.scale,
      layer.warp,
      layer.detail.toDouble(),
    );
    vec4(layer.angle, layer.seed, layer.density, layer.speed);
    vec4(layer.contrast, layer.balance, layer.grain, 0);
  }

  final resolvedTint = tint;
  vec4(width, height, time, output.toDouble());
  vec4(recipe.mix, recipe.blend.toDouble(), recipe.exposure, recipe.saturation);
  vec4(recipe.relief, recipe.lightAngle, recipe.vignette, recipe.roughness);
  vec4(recipe.palette.dark.r, recipe.palette.dark.g, recipe.palette.dark.b, 1);
  vec4(recipe.palette.mid.r, recipe.palette.mid.g, recipe.palette.mid.b, 1);
  vec4(recipe.palette.bright.r, recipe.palette.bright.g, recipe.palette.bright.b, 1);
  vec4(recipe.offsetX, recipe.offsetY, recipe.zoom, compare);
  vec4(recipe.grain, recipe.lightIntensity, mask ? 1 : 0, 0);
  layer(recipe.a);
  layer(recipe.b);
  vec4(amount, tintAmount, 0, 0);
  vec4(
    resolvedTint?.r ?? recipe.palette.bright.r,
    resolvedTint?.g ?? recipe.palette.bright.g,
    resolvedTint?.b ?? recipe.palette.bright.b,
    0,
  );
  return uniforms;
}

/// Writes [uniforms] into [shader] starting at slot 0.
void applyBrandMaterialUniforms(FragmentShader shader, Float32List uniforms) {
  for (var i = 0; i < uniforms.length; i++) {
    shader.setFloat(i, uniforms[i]);
  }
}
