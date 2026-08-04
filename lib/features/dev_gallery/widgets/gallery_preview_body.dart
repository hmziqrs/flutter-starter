import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Canonical gallery preview scaffold: [Center] > [ConstrainedBox] capped at
/// [AppSizes.formContentMaxWidth] > [Padding] of [AppSpacing.screenPadding].
///
/// Case previews that previously hand-rolled this Center/ConstrainedBox/Padding
/// triplet should compose around this widget instead. When a preview needs extra
/// structure (e.g. a [SingleChildScrollView]), wrap or nest it rather than
/// reimplementing the triplet.
class GalleryPreviewBody extends StatelessWidget {
  const GalleryPreviewBody({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: child,
        ),
      ),
    );
  }
}
