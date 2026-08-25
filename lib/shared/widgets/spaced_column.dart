import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class SpacedColumn extends StatelessWidget {
  const SpacedColumn({
    required this.children,
    this.gap = AppSpacing.sm,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    super.key,
  });

  final double gap;

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: gap),
          children[index],
        ],
      ],
    );
  }
}
