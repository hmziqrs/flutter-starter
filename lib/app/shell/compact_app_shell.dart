import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

class CompactAppShell extends StatelessWidget {
  const CompactAppShell({
    required this.selectedIndex,
    required this.onSelectTab,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final void Function(int) onSelectTab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return FScaffold(
      childPad: false,
      footer: FBottomNavigationBar(
        key: const ValueKey('compact-navigation'),
        index: selectedIndex,
        onChange: onSelectTab,
        // Brand rules: the active destination reads as the muted selection —
        // a quiet foreground label, never an orange announcement — with only
        // the icon carrying the brand color (APP-BLOCKS AppShell states).
        // Press feedback is color only, and labels never exceed w600.
        style: FBottomNavigationBarStyleDelta.delta(
          itemStyle: FBottomNavigationBarItemStyleDelta.delta(
            tappableStyle: const FTappableStyleDelta.delta(motion: FTappableMotion.none),
            textStyle: FVariantsDelta.delta([
              FVariantOperation.match(
                {FTappableVariant.selected},
                TextStyleDelta.delta(
                  color: context.theme.colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ),
        children: [
          FBottomNavigationBarItem(
            icon: const Icon(FLucideIcons.house),
            label: Text(translations.navigation.home),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FLucideIcons.badgeDollarSign),
            label: Text(translations.navigation.pricing),
          ),
          FBottomNavigationBarItem(
            icon: const Icon(FLucideIcons.settings),
            label: Text(translations.navigation.settings),
          ),
        ],
      ),
      child: child,
    );
  }
}
