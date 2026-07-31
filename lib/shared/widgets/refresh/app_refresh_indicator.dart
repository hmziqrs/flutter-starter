import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.refreshingLabel,
    super.key,
  });

  final Future<void> Function() onRefresh;

  final Widget child;

  final double displacement;

  final double edgeOffset;

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
