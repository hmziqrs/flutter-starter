import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class AppSidebarItemGroup extends StatelessWidget {
  const AppSidebarItemGroup({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: context.spacing.xs),
          children[index],
        ],
      ],
    );
  }
}
