import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/shell/compact_app_shell.dart';
import 'package:starter/app/shell/expanded_app_shell.dart';
import 'package:starter/app/shell/television_app_shell.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required StatefulNavigationShell navigationShell,
    this.showDeveloperEntry = false,
    super.key,
  }) : navigationShell = navigationShell,
       child = navigationShell;

  const AppShell.preview({required this.child, this.showDeveloperEntry = false, super.key})
    : navigationShell = null;

  final StatefulNavigationShell? navigationShell;
  final Widget child;

  /// Whether the shell exposes the developer gallery entry (dev builds only).
  final bool showDeveloperEntry;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// The desktop sidebar starts collapsed to the icon rail — the 256px
  /// expanded sidebar claimed too much of the content width. The toggle in
  /// the sidebar switches between the two for the current session.
  bool _sidebarExpanded = false;

  int get _selectedIndex => widget.navigationShell?.currentIndex ?? 0;

  void _onSelectTab(int index) {
    final shell = widget.navigationShell;
    if (shell == null) return;
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  void _toggleSidebar() => setState(() => _sidebarExpanded = !_sidebarExpanded);

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
            child: widget.child,
          );
        }

        return switch (layoutClass) {
          AppLayoutClass.compact => CompactAppShell(
            selectedIndex: _selectedIndex,
            onSelectTab: _onSelectTab,
            child: widget.child,
          ),
          AppLayoutClass.medium => ExpandedAppShell(
            selectedIndex: _selectedIndex,
            compactSidebar: true,
            onSelectTab: _onSelectTab,
            showDeveloperEntry: widget.showDeveloperEntry,
            expanded: _sidebarExpanded,
            onToggleSidebar: _toggleSidebar,
            child: widget.child,
          ),
          AppLayoutClass.expanded => ExpandedAppShell(
            selectedIndex: _selectedIndex,
            compactSidebar: false,
            onSelectTab: _onSelectTab,
            showDeveloperEntry: widget.showDeveloperEntry,
            expanded: _sidebarExpanded,
            onToggleSidebar: _toggleSidebar,
            child: widget.child,
          ),
        };
      },
    );
  }
}
