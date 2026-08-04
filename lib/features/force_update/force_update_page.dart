import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({
    required this.state,
    required this.onUpdateNow,
    super.key,
  });

  final ForceUpdateState state;

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
                padding: AppSpacing.screenPadding,
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
