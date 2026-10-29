import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

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
        style: context.theme.cardStyle.titleTextStyle,
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
            style: context.theme.cardStyle.subtitleTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return AppCard(
      key: const ValueKey('loading-state-view'),
      child: Center(
        child: SingleChildScrollView(
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
  }
}
