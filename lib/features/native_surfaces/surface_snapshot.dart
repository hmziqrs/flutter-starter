import 'package:freezed_annotation/freezed_annotation.dart';

part 'surface_snapshot.freezed.dart';

/// What the app is doing, in the words the OS surfaces should show.
enum SurfaceStatus { idle, active, success, warning, failure }

/// One menu entry on a surface that has menus (macOS menu bar, Windows and
/// Linux tray), or one tap target on a widget.
@freezed
abstract class SurfaceAction with _$SurfaceAction {
  const factory SurfaceAction({required String label, required String route}) = _SurfaceAction;

  const SurfaceAction._();

  Map<String, Object?> toJson() => <String, Object?>{'label': label, 'route': route};
}

/// Everything a native surface renders: home and lock screen widgets, Live
/// Activities and Android live updates, the macOS menu bar, and the Windows and
/// Linux trays. See docs/native_surfaces.md, the contract every platform follows.
///
/// All text arrives already localized, so no platform needs its own copy.
@freezed
abstract class SurfaceSnapshot with _$SurfaceSnapshot {
  const factory SurfaceSnapshot({
    required String title,
    required String subtitle,
    required DateTime updatedAt,

    /// The main figure, already formatted, such as "48,210" or "72%".
    String? value,

    /// The value's caption, such as "Visitors".
    String? valueLabel,

    /// Completion from 0 to 1. Null means nothing is in progress.
    double? progress,
    @Default(SurfaceStatus.idle) SurfaceStatus status,

    /// Where tapping the surface goes. Must pass `isOpenableSurfaceRoute`.
    @Default('/') String route,
    @Default(<SurfaceAction>[]) List<SurfaceAction> actions,
  }) = _SurfaceSnapshot;

  const SurfaceSnapshot._();

  Map<String, Object?> toJson() => <String, Object?>{
    'schema': schemaVersion,
    'title': title,
    'subtitle': subtitle,
    'value': value,
    'valueLabel': valueLabel,
    'progress': progress?.clamp(0.0, 1.0),
    'status': status.name,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'route': route,
    'actions': <Map<String, Object?>>[for (final action in actions) action.toJson()],
  };

  /// Raised when the JSON changes shape, so older widgets can ignore what they
  /// cannot read instead of misreading it.
  static const int schemaVersion = 1;
}
