import 'package:flutter/material.dart';
import 'package:starter/shared/motion/app_motion.dart';

class CollapsingBannerSlot extends StatelessWidget {
  const CollapsingBannerSlot({this.child, super.key});

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
