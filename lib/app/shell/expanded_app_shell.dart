import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_sidebar_item_group.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';

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
    final navigationInset = context.spacing.sm;
    final itemPadding = context.theme.sidebarStyle.groupStyle.itemStyle.padding.resolve(
      Directionality.of(context),
    );

    return FScaffold(
      key: ValueKey(compactSidebar ? 'medium-shell' : 'expanded-shell'),
      childPad: false,
      sidebar: SizedBox(
        width: width,
        child: FSidebar.raw(
          key: const ValueKey('expanded-navigation'),
          // The compact sidebar (88px) cannot hold the wordmark without
          // squeezing or clipping it, so the wordmark header only shows in the
          // expanded sidebar where the name always fits on one line.
          header: compactSidebar
              ? null
              : SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      navigationInset + itemPadding.left,
                      context.spacing.lg,
                      navigationInset + itemPadding.right,
                      context.spacing.sm,
                    ),
                    // Minimal dependent fix from the settings-profile area:
                    // long translated names (ar) overflow the sidebar, so the
                    // wordmark scales down instead of overflowing.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: AppWordmark(
                        key: const ValueKey('expanded-navigation-brand'),
                        name: translations.app.name,
                      ),
                    ),
                  ),
                ),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: navigationInset),
            children: [
              AppSidebarItemGroup(
                children: [
                  FSidebarItem(
                    key: const ValueKey('expanded-navigation-home'),
                    selected: selectedIndex == 0,
                    icon: const Icon(FLucideIcons.house),
                    label: Text(translations.navigation.home),
                    onPress: () => onSelectTab(0),
                  ),
                  FSidebarItem(
                    key: const ValueKey('expanded-navigation-pricing'),
                    selected: selectedIndex == 1,
                    icon: const Icon(FLucideIcons.badgeDollarSign),
                    label: Text(translations.navigation.pricing),
                    onPress: () => onSelectTab(1),
                  ),
                  FSidebarItem(
                    key: const ValueKey('expanded-navigation-settings'),
                    selected: selectedIndex == 2,
                    icon: const Icon(FLucideIcons.settings),
                    label: Text(translations.navigation.settings),
                    onPress: () => onSelectTab(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      child: child,
    );
  }
}
