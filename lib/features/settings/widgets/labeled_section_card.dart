import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

/// A titled settings section: an outline card with the section title set one
/// step above body text at medium weight, never uppercase.
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
          Text(
            title,
            style: context.theme.typography.body.md.copyWith(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: context.spacing.lg),
          child,
        ],
      ),
    );
  }
}
