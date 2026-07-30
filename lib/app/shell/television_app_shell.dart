import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';

/// The ten-foot shell shared by Android TV and tvOS presentations.
///
/// Navigation remains callback-driven so branch ownership stays with the
/// composition root and go_router never leaks into this presentation.
class TelevisionAppShell extends StatefulWidget {
  const TelevisionAppShell({
    required this.selectedIndex,
    required this.onSelectTab,
    required this.child,
    super.key,
  }) : assert(
         0 <= selectedIndex && selectedIndex < _destinationCount,
         'selectedIndex must identify a television navigation destination.',
       );

  static const _destinationCount = 3;

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final Widget child;

  @override
  State<TelevisionAppShell> createState() => _TelevisionAppShellState();
}

class _TelevisionAppShellState extends State<TelevisionAppShell> {
  late final List<FocusNode> _destinationFocusNodes = [
    FocusNode(debugLabel: 'television.navigation.home'),
    FocusNode(debugLabel: 'television.navigation.pricing'),
    FocusNode(debugLabel: 'television.navigation.settings'),
  ];
  late final FocusScopeNode _navigationScopeNode = FocusScopeNode(
    debugLabel: 'television.navigation.region',
  );
  late final FocusScopeNode _contentScopeNode = FocusScopeNode(
    debugLabel: 'television.content.region',
  );
  late final ReadingOrderTraversalPolicy _contentTraversalPolicy = ReadingOrderTraversalPolicy();
  late final Map<Type, Action<Intent>> _directionalActions = {
    DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
      onInvoke: _handleDirectionalFocus,
    ),
  };
  Timer? _initialFocusTimer;
  Timer? _selectionFocusTimer;

  FocusNode get _selectedDestinationFocusNode {
    return _destinationFocusNodes[widget.selectedIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusColdStartIfNeeded();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusColdStartIfNeeded();
      });
    });
    _initialFocusTimer = Timer(
      AppMotion.deliberate,
      _focusColdStartIfNeeded,
    );
  }

  @override
  void didUpdateWidget(covariant TelevisionAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final navigationHadFocus = _navigationScopeNode.hasFocus;
    if (oldWidget.selectedIndex != widget.selectedIndex && navigationHadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusSelectedDestination();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusColdStartIfNeeded();
          });
        }
      });
      _selectionFocusTimer?.cancel();
      _selectionFocusTimer = Timer(
        AppMotion.deliberate,
        _focusColdStartIfNeeded,
      );
    }
  }

  @override
  void dispose() {
    _initialFocusTimer?.cancel();
    _selectionFocusTimer?.cancel();
    for (final node in _destinationFocusNodes) {
      node.dispose();
    }
    _navigationScopeNode.dispose();
    _contentScopeNode.dispose();
    super.dispose();
  }

  List<_TelevisionDestinationData> _destinations(BuildContext context) => [
    _TelevisionDestinationData(
      id: 'home',
      label: context.t.navigation.home,
      icon: FLucideIcons.house,
    ),
    _TelevisionDestinationData(
      id: 'pricing',
      label: context.t.navigation.pricing,
      icon: FLucideIcons.badgeDollarSign,
    ),
    _TelevisionDestinationData(
      id: 'settings',
      label: context.t.navigation.settings,
      icon: FLucideIcons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.presentationTokens;
    final focusTargetHeight = math.max(
      tokens.controlMinHeight,
      tokens.focusTargetMinSize,
    );
    final destinations = _destinations(context);

    return Actions(
      actions: _directionalActions,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: FScaffold(
          key: const ValueKey('television-shell'),
          childPad: false,
          sidebar: SizedBox(
            key: const ValueKey('television-navigation-region'),
            width: tokens.navigationWidth,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: _handleNavigationRegionFocus,
              child: FocusTraversalGroup(
                key: const ValueKey('television-navigation-traversal-group'),
                policy: WidgetOrderTraversalPolicy(),
                child: FSidebar.raw(
                  key: const ValueKey('television-navigation'),
                  focusNode: _navigationScopeNode,
                  style: FSidebarStyleDelta.delta(
                    constraints: BoxConstraints.tightFor(
                      width: tokens.navigationWidth,
                    ),
                  ),
                  header: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      tokens.cardGap,
                      tokens.cardGap,
                      tokens.cardGap,
                      tokens.cardGap / 2,
                    ),
                    child: Text(
                      key: const ValueKey('television-navigation-brand'),
                      context.t.app.name,
                      style: context.theme.typography.display.lg,
                    ),
                  ),
                  child: ListView(
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.focusOutlineWidth + tokens.focusSpacing,
                      vertical: tokens.cardGap / 2,
                    ),
                    children: [
                      for (final (index, destination) in destinations.indexed)
                        _TelevisionDestination(
                          id: destination.id,
                          label: destination.label,
                          icon: destination.icon,
                          selected: widget.selectedIndex == index,
                          autofocus: widget.selectedIndex == index,
                          focusNode: _destinationFocusNodes[index],
                          minimumHeight: focusTargetHeight,
                          gap: index == destinations.length - 1 ? 0 : tokens.cardGap,
                          tokens: tokens,
                          onPress: () => widget.onSelectTab(index),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child: SizedBox.expand(
            key: const ValueKey('television-content-region'),
            child: FocusScope.withExternalFocusNode(
              focusScopeNode: _contentScopeNode,
              child: FocusTraversalGroup(
                key: const ValueKey('television-content-traversal-group'),
                policy: _contentTraversalPolicy,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Object? _handleDirectionalFocus(DirectionalFocusIntent intent) {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) {
      return null;
    }

    final startedInNavigation = _navigationScopeNode.hasFocus;
    final startedInContent = _contentScopeNode.hasFocus;
    final direction = Directionality.of(context);
    final towardContent = direction == TextDirection.ltr
        ? TraversalDirection.right
        : TraversalDirection.left;
    final towardNavigation = direction == TextDirection.ltr
        ? TraversalDirection.left
        : TraversalDirection.right;

    if (startedInNavigation && intent.direction == towardContent) {
      _focusContent();
      return null;
    }

    if (focused.focusInDirection(intent.direction)) {
      return null;
    }

    if (startedInContent && intent.direction == towardNavigation) {
      _focusSelectedDestination();
      return null;
    }
    return null;
  }

  void _focusContent() {
    final previousTarget = _rememberedContentTarget();
    if (previousTarget != null) {
      previousTarget.requestFocus();
      return;
    }

    final descendants = _contentScopeNode.traversalDescendants.where(
      (node) => node is! FocusScopeNode && node.canRequestFocus && !node.skipTraversal,
    );
    final ordered = _contentTraversalPolicy.sortDescendants(
      descendants,
      _contentScopeNode,
    );
    ordered.firstOrNull?.requestFocus();
  }

  FocusNode? _rememberedContentTarget() {
    var target = _contentScopeNode.focusedChild;
    while (target is FocusScopeNode) {
      target = target.focusedChild;
    }
    if (target == null || !target.canRequestFocus || target.skipTraversal) {
      return null;
    }
    return target;
  }

  void _focusSelectedDestination() {
    _selectedDestinationFocusNode.requestFocus();
  }

  void _focusColdStartIfNeeded() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (mounted && (primaryFocus == null || primaryFocus is FocusScopeNode)) {
      _focusSelectedDestination();
    }
  }

  void _handleNavigationRegionFocus(bool focused) {
    if (!focused) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _navigationScopeNode.hasFocus && !_selectedDestinationFocusNode.hasFocus) {
        _focusSelectedDestination();
      }
    });
  }
}

class _TelevisionDestinationData {
  const _TelevisionDestinationData({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class _TelevisionDestination extends StatelessWidget {
  const _TelevisionDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selected,
    required this.autofocus,
    required this.focusNode,
    required this.minimumHeight,
    required this.gap,
    required this.tokens,
    required this.onPress,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final bool autofocus;
  final FocusNode focusNode;
  final double minimumHeight;
  final double gap;
  final AppPresentationTokens tokens;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: ConstrainedBox(
        key: ValueKey('television-navigation-$id-target'),
        constraints: BoxConstraints(minHeight: minimumHeight),
        child: FSidebarItem(
          key: ValueKey('television-navigation-$id'),
          style: FSidebarItemStyleDelta.delta(
            focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(
              color: tokens.focusColor,
              width: tokens.focusOutlineWidth,
              spacing: tokens.focusSpacing,
            ),
          ),
          selected: selected,
          autofocus: autofocus,
          focusNode: focusNode,
          icon: Icon(icon, size: tokens.controlMinHeight * 0.45),
          label: Text(label),
          onPress: onPress,
        ),
      ),
    );
  }
}
