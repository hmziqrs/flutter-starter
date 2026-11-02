import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/blocks/page_intro.dart';
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

/// Shared presentation helpers for the entry-flow screens (APP-BLOCKS type
/// scale): page titles at 24 w500 tracking-tight (tracking-tight = -0.025em,
/// the kit page intro's recipe) and muted 14 descriptions.
///
/// The app theme already carries the Onest faces and the w500 display weight;
/// these helpers only pin the scale so pages built on the raw generated theme
/// (tests, previews) read the same.
TextStyle entryPageTitleStyle(BuildContext context) {
  final typography = context.theme.typography;
  final fontSize = typography.display.xl.fontSize ?? 24;
  return typography.display.xl.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: -fontSize * 0.025,
  );
}

TextStyle entryMutedBodyStyle(BuildContext context) {
  return context.theme.typography.body.sm.copyWith(
    color: context.theme.colors.mutedForeground,
  );
}

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
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
    return FScaffold(
      key: ValueKey('auth-$screenId-page'),
      child: SafeArea(
        child: switch (layoutClass) {
          AppLayoutClass.compact => _scrollingForm(
            context,
            spacing: spacing,
            tokens: tokens,
            storageKey: 'auth-$screenId-layout-compact',
            card: false,
          ),
          AppLayoutClass.medium => _scrollingForm(
            context,
            spacing: spacing,
            tokens: tokens,
            storageKey: 'auth-$screenId-layout-medium',
            card: true,
          ),
          AppLayoutClass.expanded => Row(
            key: ValueKey('auth-$screenId-layout-expanded'),
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: _scrollPadding(context, spacing),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: tokens.readingContentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppIconTile(icon: icon),
                        SizedBox(height: spacing.lg),
                        // The kit page-intro composition for the title/intro
                        // pair (gap-6, tracking-tight), like every other
                        // shell page's opening block.
                        AppPageIntro(title: title, description: body),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _scrollingForm(
                  context,
                  spacing: spacing,
                  tokens: tokens,
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
    required AppSpacingValues spacing,
    required AppPresentationTokens tokens,
    required String storageKey,
    required bool card,
  }) {
    return ListView(
      key: PageStorageKey(storageKey),
      padding: _scrollPadding(context, spacing),
      children: [
        if (card)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.formContentMaxWidth,
              ),
              // The brand outline card (transparent fill, 1px border, no
              // shadow) — never the filled default FCard panel.
              child: AppCard(
                padding: EdgeInsets.all(spacing.xl),
                child: FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: form,
                ),
              ),
            ),
          )
        else
          FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: form,
          ),
      ],
    );
  }

  EdgeInsetsGeometry _scrollPadding(BuildContext context, AppSpacingValues spacing) {
    return EdgeInsetsDirectional.fromSTEB(
      spacing.xl,
      spacing.xl2,
      spacing.xl,
      spacing.xl3 + MediaQuery.viewInsetsOf(context).bottom,
    );
  }
}
