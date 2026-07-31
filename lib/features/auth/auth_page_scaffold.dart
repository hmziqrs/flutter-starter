import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';

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
                    constraints: BoxConstraints(
                      maxWidth: context.presentationTokens.readingContentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: context.spacing.xl3),
                        SizedBox(height: context.spacing.xl),
                        Text(title, style: context.theme.typography.display.xl4),
                        SizedBox(height: context.spacing.lg),
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
              constraints: BoxConstraints(
                maxWidth: context.presentationTokens.formContentMaxWidth,
              ),
              child: FCard(
                child: Padding(
                  padding: EdgeInsets.all(context.spacing.xl),
                  child: FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    child: form,
                  ),
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

  EdgeInsetsGeometry _scrollPadding(BuildContext context) {
    return EdgeInsetsDirectional.fromSTEB(
      context.spacing.xl,
      context.spacing.xl2,
      context.spacing.xl,
      context.spacing.xl3 + MediaQuery.viewInsetsOf(context).bottom,
    );
  }
}
