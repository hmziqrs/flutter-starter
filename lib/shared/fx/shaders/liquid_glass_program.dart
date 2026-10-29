import 'dart:ui' show FragmentProgram, FragmentShader;

/// Where the compiled liquid glass program lives in the asset bundle
/// (declared under `flutter: shaders:` in pubspec.yaml).
const String liquidGlassShaderAsset = 'assets/shaders/liquid_glass.frag';

/// The compiled liquid glass fragment program, for `ImageFilter.shader`
/// backdrop refraction.
///
/// The engine binds the backdrop snapshot to the shader's first sampler and
/// writes the bound texture's size into its first float uniform (`uSize`);
/// the widget only writes the lens uniforms. One shader per surface — call
/// [newShader] once per mounted `LiquidGlass` and dispose it with the state.
final class LiquidGlassProgram {
  LiquidGlassProgram._(this._program);

  static LiquidGlassProgram? _instance;

  /// Loads (and memoizes) the compiled shader program.
  static Future<LiquidGlassProgram> load() async {
    final existing = _instance;
    if (existing != null) {
      return existing;
    }
    final program = await FragmentProgram.fromAsset(liquidGlassShaderAsset);
    return _instance = LiquidGlassProgram._(program);
  }

  final FragmentProgram _program;

  /// Builds a fresh shader with the lens uniforms applied.
  ///
  /// Slot layout (float uniforms; slot 0/1 `uSize` belongs to the engine):
  /// 2 corner radius, 3 edge width, 4 refraction, 5 dispersion,
  /// 6 rim highlight.
  FragmentShader newShader({
    required double radius,
    required double edgeWidth,
    required double refraction,
    required double dispersion,
    required double highlight,
  }) {
    final shader = _program.fragmentShader()
      ..setFloat(2, radius)
      ..setFloat(3, edgeWidth)
      ..setFloat(4, refraction)
      ..setFloat(5, dispersion)
      ..setFloat(6, highlight);
    return shader;
  }

  /// Re-applies the lens uniforms to an existing shader.
  void applyLens(
    FragmentShader shader, {
    required double radius,
    required double edgeWidth,
    required double refraction,
    required double dispersion,
    required double highlight,
  }) {
    shader
      ..setFloat(2, radius)
      ..setFloat(3, edgeWidth)
      ..setFloat(4, refraction)
      ..setFloat(5, dispersion)
      ..setFloat(6, highlight);
  }
}
