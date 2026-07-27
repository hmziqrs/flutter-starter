import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// A themed wrapper over Flutter's Material [RefreshIndicator].
///
/// The spinner is colored with the active accent
/// (`context.theme.colors.primary`, baked in by
/// `ForuiThemeFactory._accentColors`) so the indicator tracks the user's chosen
/// accent without hand-editing the ForUI theme factory (audit #8). The
/// drag-triggered [onRefresh] is awaited and *always resolves* — the refresh
/// action is never gated on motion.
///
/// Motion is guarded (audit #5): the spinner is Flutter's native indicator
/// animation; under `MediaQuery.disableAnimationsOf` the spinner is rendered
/// transparent (no visible animation) and a localized `Semantics` live region
/// announces the refresh progress instead. No custom spin is introduced, so no
/// `AppMotion` token is required; tests using bounded frame pumps never block
/// on the animation.
///
/// Pure wrapper: no plugin, no persistence, no side effects beyond what the
/// feature-supplied [onRefresh] performs. The first concrete consumer is
/// `HomePage` (recent-activity pull-to-refresh); the designated deferred
/// consumers are search-results (search-pagination) and cached lists
/// (offline-cache) per the feature spec (audit #3).
class AppRefreshIndicator extends StatefulWidget {
  /// Creates an [AppRefreshIndicator].
  const AppRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.refreshingLabel,
    super.key,
  });

  /// Typed refresh callback. Feature-supplied: a feature with no backend wires
  /// this to surface `common.notConnected` honestly and never fakes success
  /// (audit #13).
  final Future<void> Function() onRefresh;

  /// The scrollable this indicator wraps. Must report overscroll notifications
  /// (e.g. `ListView`, `GridView`, `CustomScrollView`).
  final Widget child;

  /// Distance from the top edge where the spinner rests while refreshing.
  final double displacement;

  /// Offset from the top edge before the indicator can be dragged.
  final double edgeOffset;

  /// Optional localized label announced while refreshing. Defaults to
  /// `common.loading`.
  final String? refreshingLabel;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) {
      // Drop a re-entrant drag: RefreshIndicator can fire while a prior refresh
      // is still in flight.
      return;
    }
    setState(() => _isRefreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.theme.colors.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final label = widget.refreshingLabel ?? context.t.common.loading;

    return Semantics(
      container: true,
      liveRegion: _isRefreshing,
      label: _isRefreshing ? label : null,
      child: RefreshIndicator(
        key: const ValueKey('app-refresh-indicator'),
        onRefresh: _handleRefresh,
        // Under reduce-motion the native spinning arrow is hidden (transparent)
        // and the Semantics live region above carries the signal; the refresh
        // Future still resolves via _handleRefresh.
        color: reduceMotion ? const Color(0x00000000) : accent,
        backgroundColor: reduceMotion ? const Color(0x00000000) : null,
        displacement: widget.displacement,
        edgeOffset: widget.edgeOffset,
        child: widget.child,
      ),
    );
  }
}
