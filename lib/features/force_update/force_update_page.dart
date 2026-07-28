import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Full-screen, non-dismissible hard-update block.
///
/// Wraps the body in a [PopScope] with `canPop: false` so the platform back
/// gesture / Escape cannot dismiss the block. It is **not** wrapped in
/// `EscapeDismissibleOverlay` (unlike the soft dialog): a hard block is a true
/// trap. The only affordance is "Update now", wired by the composition root to
/// the store deep-link via `url_launcher`. The page itself performs no side
/// effects and calls no plugin — every action goes through the [onUpdateNow]
/// callback (C2: no widget calls a plugin directly).
///
/// Public constructor remains usable by `ProductionPageFactory<ForceUpdateState>`
/// adapters (the dev-gallery renders this page from a typed fixture state).
class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({
    required this.state,
    required this.onUpdateNow,
    super.key,
  });

  final ForceUpdateState state;

  /// Opens the store deep-link carried by [state].
  ///
  /// Wired by the composition root to `url_launcher` with the state's storeUrl.
  final VoidCallback onUpdateNow;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return PopScope(
      canPop: false,
      child: FScaffold(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.formContentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translations.forceUpdate.title,
                      key: const ValueKey('force-update-title'),
                      style: context.theme.typography.display.xl,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.message ?? translations.forceUpdate.body,
                      key: const ValueKey('force-update-body'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FButton(
                      key: const ValueKey('force-update-update-now'),
                      onPress: onUpdateNow,
                      child: Text(translations.forceUpdate.updateNow),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
