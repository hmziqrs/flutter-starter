import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/shell/compact_app_shell.dart';
import 'package:starter/app/shell/expanded_app_shell.dart';
import 'package:starter/app/shell/television_app_shell.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

class AppShell extends StatelessWidget {
  const AppShell({required StatefulNavigationShell navigationShell, super.key})
    : navigationShell = navigationShell,
      child = navigationShell;

  const AppShell.preview({required this.child, super.key}) : navigationShell = null;

  final StatefulNavigationShell? navigationShell;
  final Widget child;

  int get _selectedIndex => navigationShell?.currentIndex ?? 0;

  void _onSelectTab(int index) {
    final shell = navigationShell;
    if (shell == null) return;
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final presentationPolicy =
        AppPresentationPolicy.maybeOf(context) ??
        const AppPresentationPolicy(
          viewingEnvironment: AppViewingEnvironment.nearField,
          interactionPolicy: AppInteractionPolicy.touch,
        );
    return AppLayoutScope(
      builder: (context, layoutClass) {
        if (presentationPolicy.isTenFoot) {
          return TelevisionAppShell(
            selectedIndex: _selectedIndex,
            onSelectTab: _onSelectTab,
            child: child,
          );
        }

        return switch (layoutClass) {
          AppLayoutClass.compact => CompactAppShell(
            selectedIndex: _selectedIndex,
            onSelectTab: _onSelectTab,
            child: child,
          ),
          AppLayoutClass.medium => ExpandedAppShell(
            selectedIndex: _selectedIndex,
            compactSidebar: true,
            onSelectTab: _onSelectTab,
            child: child,
          ),
          AppLayoutClass.expanded => ExpandedAppShell(
            selectedIndex: _selectedIndex,
            compactSidebar: false,
            onSelectTab: _onSelectTab,
            child: child,
          ),
        };
      },
    );
  }
}
