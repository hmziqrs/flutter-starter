import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// A [FCard] that pads its [child] by [padding].
///
/// Extracts the repeated `FCard > Padding(all AppSpacing.lg) > child` shape used
/// across settings, profile, pricing, and dev-gallery screens. The card's border,
/// radius, and other visuals come from the ambient [FCardStyle] exactly as a plain
/// [FCard] would; only the inner padding is applied. Sites that need a different
/// inset pass [padding] explicitly so nothing moves visually.
class AppCard extends StatelessWidget {
  /// Creates a padded card.
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.style = const FCardStyleDelta.context(),
    this.clipBehavior = Clip.none,
    super.key,
  });

  /// The padding applied around [child].
  ///
  /// Defaults to `EdgeInsets.all(AppSpacing.lg)` (16) to match the historical
  /// card shape. The unused `cardPadding` presentation token (24) remains
  /// available if a larger inset is ever desired.
  final EdgeInsetsGeometry padding;

  /// The [FCardStyle] delta. Defaults to inheriting from the ambient theme.
  final FCardStyleDelta style;

  /// The clip behavior applied to the card's content. Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FCard(
      style: style,
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
