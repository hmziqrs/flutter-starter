import 'dart:ui' show Color;
import 'package:flutter/foundation.dart' show immutable;

/// The `hmziq-material-v2` schema marker carried by portable material recipes.
const String brandMaterialSchema = 'hmziq-material-v2';

/// One material layer: a shape mode with its field, warp and tone settings.
///
/// Mirrors `ShaderLayer` in the brand kit's `shaders/catalog.ts`; [clamped]
/// applies the same ranges and integer rounding the catalog's normalizer
/// uses, so a pasted or programmatically built layer can never push the
/// shader out of spec.
@immutable
final class BrandMaterialLayer {
  /// A fully specified layer. Call [clamped] (or build through `fromMap`) to
  /// enforce the schema ranges.
  const BrandMaterialLayer({
    this.mode = 0,
    this.scale = 1,
    this.warp = 0.5,
    this.detail = 5,
    this.angle = 0,
    this.seed = 17,
    this.density = 1,
    this.speed = 0.35,
    this.contrast = 1.5,
    this.balance = -0.04,
    this.grain = 0.38,
  });

  /// Parses a layer patch from a decoded JSON map, falling back to the
  /// defaults for absent keys and clamping every value into schema range.
  factory BrandMaterialLayer.fromMap(Object? value) {
    final map = _objectMap(value, 'layer');
    const fallback = BrandMaterialLayer();
    return BrandMaterialLayer(
      mode: _intIn(map, 'mode', fallback.mode, _layerModeRange),
      scale: _doubleIn(map, 'scale', fallback.scale, _scaleRange),
      warp: _doubleIn(map, 'warp', fallback.warp, _warpRange),
      detail: _intIn(map, 'detail', fallback.detail, _detailRange),
      angle: _doubleIn(map, 'angle', fallback.angle, _angleRange),
      seed: _doubleIn(map, 'seed', fallback.seed, _seedRange),
      density: _doubleIn(map, 'density', fallback.density, _densityRange),
      speed: _doubleIn(map, 'speed', fallback.speed, _layerSpeedRange),
      contrast: _doubleIn(map, 'contrast', fallback.contrast, _contrastRange),
      balance: _doubleIn(map, 'balance', fallback.balance, _balanceRange),
      grain: _doubleIn(map, 'grain', fallback.grain, _grainRange),
    ).clamped();
  }

  /// Shape mode index (0–29), one per material algorithm in the shader.
  final int mode;

  /// Field frequency multiplier.
  final double scale;

  /// Domain-warp strength.
  final double warp;

  /// Fractal octave count (2–6).
  final int detail;

  /// Field rotation, radians.
  final double angle;

  /// Lattice offset, so layers of the same mode differ.
  final double seed;

  /// How tightly the mode's signature feature packs.
  final double density;

  /// Per-layer time multiplier.
  final double speed;

  /// Tone contrast around the midpoint.
  final double contrast;

  /// Tone shift before contrast, −0.4 to 0.4.
  final double balance;

  /// Per-pixel tone grain, 0 to 1.
  final double grain;

  /// Returns a copy with the same clamps and rounding as the catalog
  /// normalizer: mode/detail/seed rounded, everything clamped into range.
  BrandMaterialLayer clamped() {
    return BrandMaterialLayer(
      mode: mode.clamp(_layerModeRange.$1, _layerModeRange.$2).round(),
      scale: scale.clamp(_scaleRange.$1, _scaleRange.$2),
      warp: warp.clamp(_warpRange.$1, _warpRange.$2),
      detail: detail.clamp(_detailRange.$1, _detailRange.$2).round(),
      angle: angle.clamp(_angleRange.$1, _angleRange.$2),
      seed: seed.clamp(_seedRange.$1, _seedRange.$2).roundToDouble(),
      density: density.clamp(_densityRange.$1, _densityRange.$2),
      speed: speed.clamp(_layerSpeedRange.$1, _layerSpeedRange.$2),
      contrast: contrast.clamp(_contrastRange.$1, _contrastRange.$2),
      balance: balance.clamp(_balanceRange.$1, _balanceRange.$2),
      grain: grain.clamp(_grainRange.$1, _grainRange.$2),
    );
  }

  BrandMaterialLayer copyWith({
    int? mode,
    double? scale,
    double? warp,
    int? detail,
    double? angle,
    double? seed,
    double? density,
    double? speed,
    double? contrast,
    double? balance,
    double? grain,
  }) {
    return BrandMaterialLayer(
      mode: mode ?? this.mode,
      scale: scale ?? this.scale,
      warp: warp ?? this.warp,
      detail: detail ?? this.detail,
      angle: angle ?? this.angle,
      seed: seed ?? this.seed,
      density: density ?? this.density,
      speed: speed ?? this.speed,
      contrast: contrast ?? this.contrast,
      balance: balance ?? this.balance,
      grain: grain ?? this.grain,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'mode': mode,
      'scale': scale,
      'warp': warp,
      'detail': detail,
      'angle': angle,
      'seed': seed,
      'density': density,
      'speed': speed,
      'contrast': contrast,
      'balance': balance,
      'grain': grain,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandMaterialLayer &&
          mode == other.mode &&
          scale == other.scale &&
          warp == other.warp &&
          detail == other.detail &&
          angle == other.angle &&
          seed == other.seed &&
          density == other.density &&
          speed == other.speed &&
          contrast == other.contrast &&
          balance == other.balance &&
          grain == other.grain;

  @override
  int get hashCode => Object.hash(
    mode,
    scale,
    warp,
    detail,
    angle,
    seed,
    density,
    speed,
    contrast,
    balance,
    grain,
  );
}

/// The dark/mid/bright palette ramp a recipe maps its material tone onto.
@immutable
final class BrandMaterialPalette {
  const BrandMaterialPalette({required this.dark, required this.mid, required this.bright});

  /// Parses `#rrggbb` colors; throws [ArgumentError] when the value is not
  /// three six-digit hex strings (the catalog's palette rule).
  factory BrandMaterialPalette.parse(Object? value) {
    final colors = <Color>[];
    if (value is List<Object?> && value.length == 3) {
      for (final item in value) {
        if (item is String) {
          try {
            colors.add(_hex(item));
            continue;
          } on FormatException {
            // Fall through to the shared error below.
          }
        }
        break;
      }
    }
    if (colors.length != 3) {
      throw ArgumentError.value(value, 'palette', 'The palette needs three six-digit hex colors.');
    }
    return BrandMaterialPalette(dark: colors[0], mid: colors[1], bright: colors[2]);
  }

  final Color dark;
  final Color mid;
  final Color bright;

  List<String> toMap() => <String>[_hexOf(dark), _hexOf(mid), _hexOf(bright)];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandMaterialPalette &&
          dark == other.dark &&
          mid == other.mid &&
          bright == other.bright;

  @override
  int get hashCode => Object.hash(dark, mid, bright);
}

/// A full material recipe: two layers, how they mix, the palette ramp, and
/// the finish (exposure, light, vignette, grain).
///
/// Mirrors `ShaderRecipe` in the brand kit's `shaders/catalog.ts` and the
/// `hmziq-material-v2` document schema; `fromMap` and [clamped] reproduce
/// the catalog's clamped normalization.
@immutable
final class BrandMaterialRecipe {
  /// A fully specified recipe. Call [clamped] (or build through `fromMap`)
  /// to enforce the schema ranges.
  const BrandMaterialRecipe({
    this.id = 'material',
    this.name = 'Material',
    this.a = const BrandMaterialLayer(),
    this.b = const BrandMaterialLayer(mode: 8),
    this.mix = 0,
    this.blend = 0,
    this.palette = const BrandMaterialPalette(
      dark: Color(0xFF101010),
      mid: Color(0xFF7B7974),
      bright: Color(0xFFF6F2E9),
    ),
    this.exposure = 0,
    this.saturation = 1,
    this.relief = 0.5,
    this.lightAngle = -0.65,
    this.roughness = 0.5,
    this.vignette = 0.12,
    this.grain = 0.2,
    this.lightIntensity = 0.75,
    this.zoom = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.speed = 1,
    this.time = 0,
  });

  /// Parses a recipe patch from a decoded JSON map: either a bare recipe map
  /// or an `hmziq-material-v2` document with a nested `recipe`. Throws
  /// [ArgumentError] for a wrong schema marker or a bad palette.
  factory BrandMaterialRecipe.fromMap(Object? value) {
    var map = _objectMap(value, 'recipe');
    final schema = map['schema'];
    if (schema != null && schema != brandMaterialSchema) {
      throw ArgumentError.value(schema, 'schema', 'Choose a hmziq-material-v2 recipe.');
    }
    final nested = map['recipe'];
    if (nested is Map<Object?, Object?>) {
      map = nested;
    }
    const fallback = BrandMaterialRecipe();
    final idValue = map['id'];
    final nameValue = map['name'];
    return BrandMaterialRecipe(
      id: idValue is String ? _clip(idValue) : fallback.id,
      name: nameValue is String ? _clip(nameValue) : fallback.name,
      a: map.containsKey('a') ? BrandMaterialLayer.fromMap(map['a']) : fallback.a,
      b: map.containsKey('b') ? BrandMaterialLayer.fromMap(map['b']) : fallback.b,
      mix: _doubleIn(map, 'mix', fallback.mix, _unitRange),
      blend: _intIn(map, 'blend', fallback.blend, _blendRange),
      palette: map.containsKey('palette')
          ? BrandMaterialPalette.parse(map['palette'])
          : fallback.palette,
      exposure: _doubleIn(map, 'exposure', fallback.exposure, _exposureRange),
      saturation: _doubleIn(map, 'saturation', fallback.saturation, _saturationRange),
      relief: _doubleIn(map, 'relief', fallback.relief, _reliefRange),
      lightAngle: _doubleIn(map, 'lightAngle', fallback.lightAngle, _angleRange),
      roughness: _doubleIn(map, 'roughness', fallback.roughness, _unitRange),
      vignette: _doubleIn(map, 'vignette', fallback.vignette, _unitRange),
      grain: _doubleIn(map, 'grain', fallback.grain, _grainRange),
      lightIntensity: _doubleIn(map, 'lightIntensity', fallback.lightIntensity, _unitRange),
      zoom: _doubleIn(map, 'zoom', fallback.zoom, _zoomRange),
      offsetX: _doubleIn(map, 'offsetX', fallback.offsetX, _offsetRange),
      offsetY: _doubleIn(map, 'offsetY', fallback.offsetY, _offsetRange),
      speed: _doubleIn(map, 'speed', fallback.speed, _recipeSpeedRange),
      time: _doubleIn(map, 'time', fallback.time, _timeRange),
    ).clamped();
  }

  final String id;
  final String name;
  final BrandMaterialLayer a;
  final BrandMaterialLayer b;
  final double mix;
  final int blend;
  final BrandMaterialPalette palette;
  final double exposure;
  final double saturation;
  final double relief;
  final double lightAngle;
  final double roughness;
  final double vignette;
  final double grain;
  final double lightIntensity;
  final double zoom;
  final double offsetX;
  final double offsetY;
  final double speed;
  final double time;

  /// Returns a copy with the catalog's clamps and rounding applied:
  /// blend (and layer mode/detail/seed) rounded, everything in range.
  BrandMaterialRecipe clamped() {
    return BrandMaterialRecipe(
      id: id,
      name: name,
      a: a.clamped(),
      b: b.clamped(),
      mix: mix.clamp(_unitRange.$1, _unitRange.$2),
      blend: blend.clamp(_blendRange.$1, _blendRange.$2).round(),
      palette: palette,
      exposure: exposure.clamp(_exposureRange.$1, _exposureRange.$2),
      saturation: saturation.clamp(_saturationRange.$1, _saturationRange.$2),
      relief: relief.clamp(_reliefRange.$1, _reliefRange.$2),
      lightAngle: lightAngle.clamp(_angleRange.$1, _angleRange.$2),
      roughness: roughness.clamp(_unitRange.$1, _unitRange.$2),
      vignette: vignette.clamp(_unitRange.$1, _unitRange.$2),
      grain: grain.clamp(_grainRange.$1, _grainRange.$2),
      lightIntensity: lightIntensity.clamp(_unitRange.$1, _unitRange.$2),
      zoom: zoom.clamp(_zoomRange.$1, _zoomRange.$2),
      offsetX: offsetX.clamp(_offsetRange.$1, _offsetRange.$2),
      offsetY: offsetY.clamp(_offsetRange.$1, _offsetRange.$2),
      speed: speed.clamp(_recipeSpeedRange.$1, _recipeSpeedRange.$2),
      time: time.clamp(_timeRange.$1, _timeRange.$2),
    );
  }

  BrandMaterialRecipe copyWith({
    String? id,
    String? name,
    BrandMaterialLayer? a,
    BrandMaterialLayer? b,
    double? mix,
    int? blend,
    BrandMaterialPalette? palette,
    double? exposure,
    double? saturation,
    double? relief,
    double? lightAngle,
    double? roughness,
    double? vignette,
    double? grain,
    double? lightIntensity,
    double? zoom,
    double? offsetX,
    double? offsetY,
    double? speed,
    double? time,
  }) {
    return BrandMaterialRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      a: a ?? this.a,
      b: b ?? this.b,
      mix: mix ?? this.mix,
      blend: blend ?? this.blend,
      palette: palette ?? this.palette,
      exposure: exposure ?? this.exposure,
      saturation: saturation ?? this.saturation,
      relief: relief ?? this.relief,
      lightAngle: lightAngle ?? this.lightAngle,
      roughness: roughness ?? this.roughness,
      vignette: vignette ?? this.vignette,
      grain: grain ?? this.grain,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      zoom: zoom ?? this.zoom,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      speed: speed ?? this.speed,
      time: time ?? this.time,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'a': a.toMap(),
      'b': b.toMap(),
      'mix': mix,
      'blend': blend,
      'palette': palette.toMap(),
      'exposure': exposure,
      'saturation': saturation,
      'relief': relief,
      'lightAngle': lightAngle,
      'roughness': roughness,
      'vignette': vignette,
      'grain': grain,
      'lightIntensity': lightIntensity,
      'zoom': zoom,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'speed': speed,
      'time': time,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandMaterialRecipe &&
          id == other.id &&
          name == other.name &&
          a == other.a &&
          b == other.b &&
          mix == other.mix &&
          blend == other.blend &&
          palette == other.palette &&
          exposure == other.exposure &&
          saturation == other.saturation &&
          relief == other.relief &&
          lightAngle == other.lightAngle &&
          roughness == other.roughness &&
          vignette == other.vignette &&
          grain == other.grain &&
          lightIntensity == other.lightIntensity &&
          zoom == other.zoom &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          speed == other.speed &&
          time == other.time;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    a,
    b,
    mix,
    blend,
    palette,
    exposure,
    saturation,
    relief,
    lightAngle,
    roughness,
    vignette,
    grain,
    lightIntensity,
    zoom,
    offsetX,
    offsetY,
    speed,
    time,
  );
}

// Schema ranges, ported from `layerRanges`/`recipeRanges` in the brand kit's
// shaders/catalog.ts.
const (double, double) _layerModeRange = (0, 29);
const (double, double) _scaleRange = (0.25, 4);
const (double, double) _warpRange = (0, 2);
const (double, double) _detailRange = (2, 6);
const (double, double) _angleRange = (-3.141592653589793, 3.141592653589793);
const (double, double) _seedRange = (0, 9999);
const (double, double) _densityRange = (0.2, 3);
const (double, double) _layerSpeedRange = (0, 2);
const (double, double) _contrastRange = (0.5, 2.5);
const (double, double) _balanceRange = (-0.4, 0.4);
const (double, double) _grainRange = (0, 1);
const (double, double) _unitRange = (0, 1);
const (double, double) _blendRange = (0, 5);
const (double, double) _exposureRange = (-1, 1);
const (double, double) _saturationRange = (0, 1.6);
const (double, double) _reliefRange = (0, 2.5);
const (double, double) _zoomRange = (0.25, 4);
const (double, double) _offsetRange = (-100, 100);
const (double, double) _recipeSpeedRange = (0.25, 2);
const (double, double) _timeRange = (0, 60);

Map<Object?, Object?> _objectMap(Object? value, String what) {
  if (value is Map<Object?, Object?>) {
    return value;
  }
  throw ArgumentError.value(value, what, 'Paste a shader recipe or settings object.');
}

double _doubleIn(Map<Object?, Object?> map, String key, double fallback, (double, double) range) {
  final value = map[key];
  if (value is! num) {
    return fallback;
  }
  return value.toDouble().clamp(range.$1, range.$2);
}

int _intIn(Map<Object?, Object?> map, String key, int fallback, (double, double) range) {
  final value = map[key];
  if (value is! num) {
    return fallback;
  }
  return value.toDouble().clamp(range.$1, range.$2).round();
}

Color _hex(String value) {
  if (value.length != 7 || !value.startsWith('#')) {
    throw FormatException('Not a six-digit hex color', value);
  }
  final rgb = int.parse(value.substring(1), radix: 16);
  return Color.fromARGB(255, (rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);
}

String _clip(String value) => value.length > 80 ? value.substring(0, 80) : value;

String _hexOf(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0')}';
}
