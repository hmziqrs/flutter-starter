import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';

class AppPresentationViewport extends StatelessWidget {
  const AppPresentationViewport({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final policy = AppPresentationPolicy.of(context);
    if (!policy.isTenFoot) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final tokens = context.presentationTokens;
    final size = mediaQuery.size;
    final viewPadding = mediaQuery.viewPadding;
    final safeFrame = EdgeInsets.fromLTRB(
      math.max(viewPadding.left, size.width * tokens.safeContentFraction),
      math.max(viewPadding.top, size.height * tokens.safeContentFraction),
      math.max(viewPadding.right, size.width * tokens.safeContentFraction),
      math.max(viewPadding.bottom, size.height * tokens.safeContentFraction),
    );

    return ColoredBox(
      key: const ValueKey('app-presentation-tv-background'),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        key: const ValueKey('app-presentation-tv-safe-frame'),
        padding: safeFrame,
        child: MediaQuery(
          data: mediaQuery.copyWith(
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
          ),
          child: child,
        ),
      ),
    );
  }
}
