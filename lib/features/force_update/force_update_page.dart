import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

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
                padding: context.screenPadding,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: _DestructiveStatusTile(
                          icon: FLucideIcons.octagonAlert,
                          tone: context.theme.brand.destructive,
                        ),
                      ),
                      SizedBox(height: context.spacing.xl),
                      Text(
                        translations.forceUpdate.title,
                        key: const ValueKey('force-update-title'),
                        style: entryPageTitleStyle(context),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.md),
                      Text(
                        state.message ?? translations.forceUpdate.body,
                        key: const ValueKey('force-update-body'),
                        style: entryMutedBodyStyle(context),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.xl2),
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
      ),
    );
  }
}

/// The status tile for the blocked page: the brand icon tile with a soft
/// destructive fill and no border (BRAND.md section 9, "a tone's soft fill
/// without the border when the color means something") — never a solid red
/// panel.
class _DestructiveStatusTile extends StatelessWidget {
  const _DestructiveStatusTile({required this.icon, required this.tone});

  final IconData icon;

  final Color tone;

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.colors.brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 24, color: tone),
    );
  }
}
