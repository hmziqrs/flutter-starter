import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

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
