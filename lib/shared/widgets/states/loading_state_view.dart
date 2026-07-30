import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';

/// A themed loading-state card for async lists that are still in flight.
///
/// Renders a centered stack inside an [FCard] built around the shared
/// [BusyIndicator] primitive. The indeterminate spinner is shown only when
/// [MediaQuery.disableAnimationsOf] is false; under reduce-motion a static
/// localized [title] label replaces it.
class LoadingStateView extends StatelessWidget {
  /// Creates a [LoadingStateView].
  const LoadingStateView({
    required this.title,
    this.value,
    this.semanticsLabel,
    super.key,
  });

  /// Localized caption shown beneath the spinner and as the static
  /// reduce-motion label (e.g. `states.loadingTitle`).
  final String title;

  /// Determinate progress fraction (`0.0..1.0`); `null` (the default) renders
  /// an indeterminate [BusyIndicator].
  final double? value;

  /// Accessibility label forwarded to the [BusyIndicator]. Defaults to [title].
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
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            key: const ValueKey('loading-state-view-title'),
            style: context.theme.cardStyle.subtitleTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return FCard(
      key: const ValueKey('loading-state-view'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
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
      ),
    );
  }
}
