import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

typedef StateViewAction = ({String label, VoidCallback onTap});

/// How a state view is accented (APP-BLOCKS states): neutral keeps the icon
/// muted and its action outline; destructive carries the error accent.
enum StateViewTone { neutral, destructive }

class StateViewCard extends StatelessWidget {
  const StateViewCard({
    required this.keyPrefix,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.tone = StateViewTone.neutral,
    super.key,
  });

  final String keyPrefix;

  final IconData icon;

  final String title;

  final String body;

  final StateViewAction? action;

  final StateViewTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final iconTone = switch (tone) {
      StateViewTone.neutral => colors.mutedForeground,
      StateViewTone.destructive => colors.destructive,
    };
    return AppCard(
      key: ValueKey(keyPrefix),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIconTile(icon: icon, tone: iconTone),
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
                variant: switch (tone) {
                  StateViewTone.neutral => FButtonVariant.outline,
                  StateViewTone.destructive => FButtonVariant.primary,
                },
                child: Text(action!.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
