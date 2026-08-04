import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

/// A section card with a `body.lg` heading above its [child].
///
/// Absorbs the historical settings `_SettingsCard` shape:
/// `AppCard > Column(title + SizedBox.lg + child)`.
class LabeledSectionCard extends StatelessWidget {
  const LabeledSectionCard({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.theme.typography.body.lg),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
