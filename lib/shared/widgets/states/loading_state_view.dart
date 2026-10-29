import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({
    required this.title,
    this.value,
    this.semanticsLabel,
    super.key,
  });

  final String title;

  final double? value;

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedSemantics = semanticsLabel ?? title;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget content;
    if (reduceMotion) {
      content = Text(
        title,
        key: const ValueKey('loading-state-view-title'),
        style: context.theme.typography.body.lg.copyWith(
          color: context.theme.colors.foreground,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BusyIndicator(value: value, semanticsLabel: resolvedSemantics),
          SizedBox(height: context.spacing.md),
          Text(
            title,
            key: const ValueKey('loading-state-view-title'),
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // APP-BLOCKS.md DataState: "No box" — the state centers in the content
    // area like the brand's empty/error columns, scrolling when unbounded
    // parents (another scroller) leave no height to center in.
    return LayoutBuilder(
      key: const ValueKey('loading-state-view'),
      builder: (context, constraints) {
        // Bounded parents center in the full height; unbounded ones
        // (another scroller) get no artificial minimum.
        final minHeight = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: MergeSemantics(
                child: Semantics(
                  label: resolvedSemantics,
                  container: true,
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
