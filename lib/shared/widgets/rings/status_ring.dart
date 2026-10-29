import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// A small ring that fills orange when active (BRAND.md s7): hollow means
/// off, filled means on, open, done or selected.
///
/// The brand's ring marker at the marker's 1.75px border: hollow takes the
/// muted text color, active fills with the accent (or a caller-passed role
/// color). Decorative: pair it with a text label that carries the meaning.
class StatusRing extends StatelessWidget {
  const StatusRing({required this.active, this.size = 10, this.color, super.key});

  /// Whether the thing the ring stands for is on, open, done or selected.
  final bool active;

  /// Square side of the ring.
  final double size;

  /// The ring's color; defaults to the theme's primary when active and the
  /// muted text color when not.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return AppRingMarker(
      filled: active,
      size: size,
      color: color ?? (active ? theme.colors.primary : theme.colors.mutedForeground),
    );
  }
}
