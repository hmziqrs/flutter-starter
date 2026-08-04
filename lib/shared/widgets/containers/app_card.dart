import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.style = const FCardStyleDelta.context(),
    this.clipBehavior = Clip.none,
    super.key,
  });

  final EdgeInsetsGeometry padding;

  final FCardStyleDelta style;

  final Clip clipBehavior;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FCard(
      style: style,
      clipBehavior: clipBehavior,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
