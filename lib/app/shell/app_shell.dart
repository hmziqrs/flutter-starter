import 'package:flutter/widgets.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/shell/compact_app_shell.dart';
import 'package:starter/app/shell/expanded_app_shell.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  int get _selectedIndex {
    if (location.startsWith(AppRoutes.pricingPath)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.settingsPath)) {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, layoutClass) => switch (layoutClass) {
        AppLayoutClass.compact => CompactAppShell(
          selectedIndex: _selectedIndex,
          child: child,
        ),
        AppLayoutClass.medium => ExpandedAppShell(
          selectedIndex: _selectedIndex,
          compactSidebar: true,
          child: child,
        ),
        AppLayoutClass.expanded => ExpandedAppShell(
          selectedIndex: _selectedIndex,
          compactSidebar: false,
          child: child,
        ),
      },
    );
  }
}
