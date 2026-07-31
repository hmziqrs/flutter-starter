import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// A themed wrapper over Flutter's Material [RefreshIndicator].
///
/// The spinner is colored with the active accent
/// (`context.theme.colors.primary`) so the indicator tracks the user's chosen
/// accent. Under `MediaQuery.disableAnimationsOf` the spinner is rendered
/// transparent (no visible animation) and a localized `Semantics` live region
/// announces the refresh progress instead; [onRefresh] still always resolves.
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.refreshingLabel,
    super.key,
  });

  /// Feature-supplied refresh callback.
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
    if (_isRefreshing) return;
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
        color: reduceMotion ? const Color(0x00000000) : accent,
        backgroundColor: reduceMotion ? const Color(0x00000000) : null,
        displacement: widget.displacement,
        edgeOffset: widget.edgeOffset,
        child: widget.child,
      ),
    );
  }
}
