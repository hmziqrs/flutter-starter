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
  /// The window width from which the sidebar opens by default, as the brand's
  /// shell does. Below this the 256dp sidebar would take too much of the page,
  /// so it starts as the icon rail.
  static const double _sidebarOpenMinWidth = 1280;

  /// The user's choice from the toggle, for this session. Null follows the
  /// window width, so the first resize still picks the right default.
  bool? _sidebarOverride;

  int get _selectedIndex => widget.navigationShell?.currentIndex ?? 0;

  void _onSelectTab(int index) {
    final shell = widget.navigationShell;
    if (shell == null) return;
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  void _toggleSidebar(bool current) => setState(() => _sidebarOverride = !current);

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

        final sidebarOpen =
            _sidebarOverride ?? MediaQuery.sizeOf(context).width >= _sidebarOpenMinWidth;
        return switch (layoutClass) {
          AppLayoutClass.compact => CompactAppShell(
            selectedIndex: _selectedIndex,
            onSelectTab: _onSelectTab,
            child: widget.child,
          ),
          AppLayoutClass.medium => ExpandedAppShell(
            selectedIndex: _selectedIndex,
            onSelectTab: _onSelectTab,
            showDeveloperEntry: widget.showDeveloperEntry,
            expanded: sidebarOpen,
            onToggleSidebar: () => _toggleSidebar(sidebarOpen),
            child: widget.child,
          ),
          AppLayoutClass.expanded => ExpandedAppShell(
            selectedIndex: _selectedIndex,
            onSelectTab: _onSelectTab,
            showDeveloperEntry: widget.showDeveloperEntry,
            expanded: sidebarOpen,
            onToggleSidebar: () => _toggleSidebar(sidebarOpen),
            child: widget.child,
          ),
        };
      },
    );
  }
}
