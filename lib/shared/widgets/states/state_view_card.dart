import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';

typedef StateViewAction = ({String label, VoidCallback onTap});

class StateViewCard extends StatelessWidget {
  const StateViewCard({
    required this.keyPrefix,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final String keyPrefix;

  final IconData icon;

  final String title;

  final String body;

  final StateViewAction? action;

  @override
  Widget build(BuildContext context) {
    return FCard(
      key: ValueKey(keyPrefix),
      child: Padding(
        padding: EdgeInsets.all(context.presentationTokens.cardPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 32),
              SizedBox(height: context.spacing.md),
              Text(
                title,
                key: ValueKey('$keyPrefix-title'),
                style: context.theme.cardStyle.titleTextStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                body,
                key: ValueKey('$keyPrefix-body'),
                style: context.theme.cardStyle.subtitleTextStyle,
                textAlign: TextAlign.center,
              ),
              if (action != null) ...<Widget>[
                SizedBox(height: context.spacing.lg),
                FButton(
                  key: ValueKey('$keyPrefix-action'),
                  onPress: action!.onTap,
                  child: Text(action!.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
