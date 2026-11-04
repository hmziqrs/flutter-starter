import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_sidebar_item_group.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';

class ExpandedAppShell extends StatelessWidget {
  const ExpandedAppShell({
    required this.selectedIndex,
    required this.onSelectTab,
    required this.child,
    this.showDeveloperEntry = false,
    this.expanded = true,
    this.onToggleSidebar,
    super.key,
  });

  final int selectedIndex;
  final void Function(int) onSelectTab;

  /// Shows the developer gallery link below the navigation destinations
  /// (dev builds only — the route itself is registered under the same gate).
  final bool showDeveloperEntry;

  /// Whether the sidebar shows its full width with labels. False renders the
  /// 48dp icon rail; [onToggleSidebar] flips it at any window width.
  final bool expanded;

  /// Called when the user taps the sidebar collapse/expand control.
  final VoidCallback? onToggleSidebar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final railMode = !expanded;
    final width = railMode ? AppSizes.compactSidebarWidth : AppSizes.expandedSidebarWidth;
    final navigationInset = context.spacing.sm;
    // The rail's own side air: 4 inside the 48px brand icon rail (the
    // expanded sidebar keeps the theme inset).
    const railInset = 4.0;
    final itemStyle = context.theme.sidebarStyle.groupStyle.itemStyle;
    final itemPadding = itemStyle.padding.resolve(Directionality.of(context));

    // The rail cannot hold readable labels, so it renders as an icon rail
    // (BRAND.md s9, labeled and readable controls): the text drops out and the
    // icon centers in the rail through symmetric padding. The item keeps its
    // name on the tooltip, whose semantics label also carries it to assistive
    // tech (BRAND.md s6: icon-only controls stay labeled).
    final iconRailStyle = railMode
        ? _iconRailStyle(itemStyle, itemPadding, width, railInset)
        : null;

    return FScaffold(
      key: ValueKey(railMode ? 'medium-shell' : 'expanded-shell'),
      childPad: false,
      sidebar: SizedBox(
        width: width,
        child: FSidebar.raw(
          key: const ValueKey('expanded-navigation'),
          // The kit's `--sidebar` fill, a step off the page color so the shell
          // reads as its own surface.
          style: .delta(
            decoration: .boxDelta(
              color: context.theme.colors.brightness == Brightness.dark
                  ? const Color(0xFF171717)
                  : const Color(0xFFFAFAFA),
            ),
          ),
          // The rail cannot hold the wordmark without squeezing or clipping it,
          // so the wordmark header only shows in the expanded sidebar where
          // the name always fits on one line.
          header: railMode
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
                    // Long translated names (ar) overflow the sidebar, so the
                    // wordmark scales down instead of overflowing.
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: AppWordmark(
                              key: const ValueKey('expanded-navigation-brand'),
                              name: translations.app.name,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _sidebarToggle(context, iconOnly: false),
                      ],
                    ),
                  ),
                ),
          // The brand shell keeps the account at the foot of the sidebar.
          footer: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: railMode ? railInset : navigationInset,
              vertical: context.spacing.sm,
            ),
            child: _AccountItem(iconRailStyle: iconRailStyle),
          ),
          child: ListView(
            // The 48px rail tightens the side air to 4 so the 36dp toggle
            // fits without clipping; the expanded sidebar keeps its inset.
            padding: EdgeInsets.symmetric(horizontal: railMode ? railInset : navigationInset),
            children: [
              if (railMode)
                Align(
                  alignment: AlignmentDirectional.center,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: context.spacing.sm),
                    child: _sidebarToggle(context, iconOnly: true),
                  ),
                ),
              AppSidebarItemGroup(
                children: [
                  _navigationItem(
                    itemKey: const ValueKey('expanded-navigation-home'),
                    icon: FLucideIcons.house,
                    label: translations.navigation.home,
                    index: 0,
                    iconRailStyle: iconRailStyle,
                  ),
                  _navigationItem(
                    itemKey: const ValueKey('expanded-navigation-pricing'),
                    icon: FLucideIcons.badgeDollarSign,
                    label: translations.navigation.pricing,
                    index: 1,
                    iconRailStyle: iconRailStyle,
                  ),
                  _navigationItem(
                    itemKey: const ValueKey('expanded-navigation-settings'),
                    icon: FLucideIcons.settings,
                    label: translations.navigation.settings,
                    index: 2,
                    iconRailStyle: iconRailStyle,
                  ),
                  if (showDeveloperEntry)
                    _galleryLinkItem(
                      itemKey: const ValueKey('expanded-navigation-gallery'),
                      iconRailStyle: iconRailStyle,
                      context: context,
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

  /// The collapse/expand control. In the expanded sidebar it sits beside the
  /// wordmark; in the rail it is a centered icon-only button at the top.
  Widget _sidebarToggle(BuildContext context, {required bool iconOnly}) {
    final label = context.t.navigation.toggleSidebar;
    final button = FButton.icon(
      key: const ValueKey('expanded-navigation-toggle'),
      variant: .ghost,
      onPress: onToggleSidebar,
      child: Semantics(
        label: label,
        child: Icon(
          iconOnly ? FLucideIcons.panelLeftOpen : FLucideIcons.panelLeftClose,
          size: 18,
        ),
      ),
    );
    return iconOnly ? Tooltip(message: label, child: button) : button;
  }

  /// The developer gallery is a full-screen route outside the shell branches,
  /// so it pushes on top of the shell (⌘Backspace / back pops home) and is
  /// never rendered selected. Dev-gated: the widget only exists when
  /// developmentToolsEnabled is on.
  Widget _galleryLinkItem({
    required Key itemKey,
    required BuildContext context,
    FSidebarItemStyleDelta? iconRailStyle,
  }) {
    final label = context.t.navigation.gallery;
    final iconRail = iconRailStyle != null;
    final item = FSidebarItem(
      key: itemKey,
      // Never selected: it is a link, not a navigation branch.
      icon: iconRail
          ? Semantics(label: label, child: const Icon(FLucideIcons.shapes))
          : const Icon(FLucideIcons.shapes),
      label: iconRail ? null : Text(label),
      style: iconRailStyle ?? const FSidebarItemStyleDelta.context(),
      onPress: () => unawaited(context.push(AppRoutes.developmentScreensPath)),
    );
    return iconRail ? Tooltip(excludeFromSemantics: true, message: label, child: item) : item;
  }

  /// Padding that centers the 16px icon inside the rail's content width,
  /// preserving the theme's vertical padding (and its touch/desktop floors).
  static FSidebarItemStyleDelta _iconRailStyle(
    FSidebarItemStyle itemStyle,
    EdgeInsets itemPadding,
    double width,
    double sideInset,
  ) {
    final iconSize = itemStyle.iconStyle.base.size ?? 16;
    var inset = (width - 2 * sideInset - iconSize) / 2;
    if (inset < 0) {
      // Extreme spacing scales can exhaust the rail; never a negative inset.
      inset = 0;
    }
    return FSidebarItemStyleDelta.delta(
      padding: EdgeInsetsGeometryDelta.value(
        itemPadding.copyWith(left: inset, right: inset),
      ),
    );
  }

  Widget _navigationItem({
    required Key itemKey,
    required IconData icon,
    required String label,
    required int index,
    FSidebarItemStyleDelta? iconRailStyle,
  }) {
    final iconRail = iconRailStyle != null;
    final item = FSidebarItem(
      key: itemKey,
      selected: selectedIndex == index,
      // The icon rail keeps its name inside the tappable's own semantics
      // node (BRAND.md s6): the label rides the icon — which lives inside
      // that boundary, unlike an outer wrapper whose annotation would merge
      // into the shared rail node — and renders nothing extra.
      icon: iconRail ? Semantics(label: label, child: Icon(icon)) : Icon(icon),
      label: iconRail ? null : Text(label),
      style: iconRailStyle ?? const FSidebarItemStyleDelta.context(),
      onPress: () => onSelectTab(index),
    );
    // The tooltip is the pointer-user's hover hint only: its semantics stay
    // out of the tree (excludeFromSemantics) so the rail's three annotations
    // cannot merge into one shared ancestor node and lose their per-item
    // names — the Semantics label above carries those instead.
    return iconRail ? Tooltip(excludeFromSemantics: true, message: label, child: item) : item;
  }
}

/// The sidebar's account entry: the profile once signed in, otherwise the way
/// to sign in. This starter has no hard login, so both are always reachable.
class _AccountItem extends ConsumerWidget {
  const _AccountItem({this.iconRailStyle});

  final FSidebarItemStyleDelta? iconRailStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final signedIn = ref.watch(sessionControllerProvider).isAuthenticated;
    final label = signedIn ? translations.home.editProfile : translations.auth.login.submit;
    final icon = signedIn ? FLucideIcons.circleUser : FLucideIcons.logIn;
    final iconRail = iconRailStyle != null;
    final item = FSidebarItem(
      key: const ValueKey('expanded-navigation-account'),
      icon: iconRail ? Semantics(label: label, child: Icon(icon)) : Icon(icon),
      label: iconRail ? null : Text(label),
      style: iconRailStyle ?? const FSidebarItemStyleDelta.context(),
      onPress: () => unawaited(
        context.push(signedIn ? AppRoutes.updateProfilePath : AppRoutes.loginPath),
      ),
    );
    return iconRail ? Tooltip(excludeFromSemantics: true, message: label, child: item) : item;
  }
}
