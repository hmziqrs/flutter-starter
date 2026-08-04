import 'package:flutter/material.dart';
import 'package:starter/shared/motion/app_motion.dart';

/// A slot that collapses to zero height when [child] is absent and animates
/// height transitions when [child] is present.
///
/// Used by the connectivity and announcement banners to share the collapsed
/// `SizedBox` + `AnimatedSize` + `disableAnimations` guard wiring.
class CollapsingBannerSlot extends StatelessWidget {
  const CollapsingBannerSlot({this.child, super.key});

  /// The banner content to display. When `null`, the slot collapses to zero
  /// height.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox(width: double.infinity, height: 0);

    if (MediaQuery.disableAnimationsOf(context)) {
      return content;
    }
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}
