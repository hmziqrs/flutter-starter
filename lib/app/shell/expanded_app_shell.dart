import 'package:exui/exui.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class ExpandedAppShell extends StatelessWidget {
  const ExpandedAppShell({
    required this.selectedIndex,
    required this.compactSidebar,
    required this.onSelectTab,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final bool compactSidebar;
  final void Function(int) onSelectTab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final width = compactSidebar ? AppSizes.compactSidebarWidth : AppSizes.expandedSidebarWidth;

    return FScaffold(
      key: ValueKey(compactSidebar ? 'medium-shell' : 'expanded-shell'),
      childPad: false,
      sidebar: SizedBox(
        width: width,
        child: FSidebar(
          key: const ValueKey('expanded-navigation'),
          header:
              Text(
                translations.app.name,
                style: context.theme.typography.display.lg,
              ).paddingOnly(
                left: context.spacing.lg,
                top: context.spacing.xl,
                right: context.spacing.lg,
                bottom: context.spacing.md,
              ),
          children: [
            FSidebarItem(
              selected: selectedIndex == 0,
              icon: const Icon(FLucideIcons.house),
              label: Text(translations.navigation.home),
              onPress: () => onSelectTab(0),
            ),
            FSidebarItem(
              selected: selectedIndex == 1,
              icon: const Icon(FLucideIcons.badgeDollarSign),
              label: Text(translations.navigation.pricing),
              onPress: () => onSelectTab(1),
            ),
            FSidebarItem(
              selected: selectedIndex == 2,
              icon: const Icon(FLucideIcons.settings),
              label: Text(translations.navigation.settings),
              onPress: () => onSelectTab(2),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}
