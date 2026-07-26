import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/shared/motion/app_motion.dart';

/// The [ShellNavigationContainerBuilder] used by the [StatefulShellRoute].
///
/// Keeps every branch proxy mounted in stable index order inside an expanding
/// [Stack], cross-fades both branches with [AppMotion] tokens, and gates each
/// branch so only the current one is interactive, focusable, semantic, and
/// ticking. The current branch is revealed with no fade on cold start or deep
/// link, rapid switches retarget the implicit opacity animation from its
/// current value, and reduce-motion ([MediaQuery.disableAnimationsOf]) is
/// honored by collapsing the duration to [Duration.zero].
Widget crossFadingBranchContainer(
  BuildContext context,
  StatefulNavigationShell shell,
  List<Widget> children,
) {
  return _CrossFadingBranchContainer(
    currentIndex: shell.currentIndex,
    children: children,
  );
}

class _CrossFadingBranchContainer extends StatelessWidget {
  const _CrossFadingBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.standard;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (index, child) in children.indexed)
          AnimatedOpacity(
            opacity: index == currentIndex ? 1 : 0,
            duration: duration,
            curve: AppMotion.standardCurve,
            child: IgnorePointer(
              ignoring: index != currentIndex,
              child: ExcludeFocus(
                excluding: index != currentIndex,
                child: ExcludeSemantics(
                  excluding: index != currentIndex,
                  child: TickerMode(
                    enabled: index == currentIndex,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
