import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/spaced_column.dart';

class AppSidebarItemGroup extends StatelessWidget {
  const AppSidebarItemGroup({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      gap: context.spacing.xs,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
