import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// The repeated adaptive shell shared by the starter's authentication forms.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.screenId,
    required this.layoutClass,
    required this.icon,
    required this.title,
    required this.body,
    required this.form,
    super.key,
  });

  final String screenId;
  final AppLayoutClass layoutClass;
  final IconData icon;
  final String title;
  final String body;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      key: ValueKey('auth-$screenId-page'),
      child: SafeArea(
        child: switch (layoutClass) {
          AppLayoutClass.compact => _scrollingForm(
            context,
            storageKey: 'auth-$screenId-layout-compact',
            card: false,
          ),
          AppLayoutClass.medium => _scrollingForm(
            context,
            storageKey: 'auth-$screenId-layout-medium',
            card: true,
          ),
          AppLayoutClass.expanded => Row(
            key: ValueKey('auth-$screenId-layout-expanded'),
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: _scrollPadding(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.readingContentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: AppSpacing.xl3),
                        const SizedBox(height: AppSpacing.xl),
                        Text(title, style: context.theme.typography.display.xl4),
                        const SizedBox(height: AppSpacing.lg),
                        Text(body, style: context.theme.typography.body.lg),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _scrollingForm(
                  context,
                  storageKey: 'auth-$screenId-expanded-form',
                  card: true,
                ),
              ),
            ],
          ),
        },
      ),
    );
  }

  Widget _scrollingForm(
    BuildContext context, {
    required String storageKey,
    required bool card,
  }) {
    return ListView(
      key: PageStorageKey(storageKey),
      padding: _scrollPadding(context),
      children: [
        if (card)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
              child: FCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: form,
                ),
              ),
            ),
          )
        else
          form,
      ],
    );
  }

  EdgeInsetsGeometry _scrollPadding(BuildContext context) {
    return EdgeInsetsDirectional.fromSTEB(
      AppSpacing.xl,
      AppSpacing.xl2,
      AppSpacing.xl,
      AppSpacing.xl3 + MediaQuery.viewInsetsOf(context).bottom,
    );
  }
}
