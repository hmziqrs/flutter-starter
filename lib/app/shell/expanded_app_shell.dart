import 'package:exui/exui.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class ExpandedAppShell extends StatelessWidget {
  const ExpandedAppShell({
    required this.selectedIndex,
    required this.compactSidebar,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final bool compactSidebar;
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
              onPress: () => context.goNamed(AppRoutes.home),
            ),
            FSidebarItem(
              selected: selectedIndex == 1,
              icon: const Icon(FLucideIcons.badgeDollarSign),
              label: Text(translations.navigation.pricing),
              onPress: () => context.goNamed(AppRoutes.pricing),
            ),
            FSidebarItem(
              selected: selectedIndex == 2,
              icon: const Icon(FLucideIcons.settings),
              label: Text(translations.navigation.settings),
              onPress: () => context.goNamed(AppRoutes.settings),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}
