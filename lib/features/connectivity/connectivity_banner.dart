import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/banners/collapsing_banner_slot.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/feedback/app_toast.dart';

class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<ConnectivityState>>(
      connectivityStatusProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        final previousState = previous?.value;
        final currentState = next.value;
        if (previousState != null &&
            previousState.isDegraded &&
            currentState == ConnectivityState.online) {
          _showBackOnlineToast(context);
        }
      },
    );
  }

  void _showBackOnlineToast(BuildContext context) {
    final translations = context.t;
    AppToast.show(
      context,
      severity: ToastSeverity.info,
      message: translations.connectivity.backOnline,
      icon: FLucideIcons.wifi,
      iconSemanticLabel: translations.connectivity.online,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectivityStatusProvider).value;
    final showBanner = ref.watch(connectivityBannerVisibleProvider);
    return _BannerSlot(state: showBanner ? state : null);
  }
}

class _BannerSlot extends StatelessWidget {
  const _BannerSlot({required this.state});

  final ConnectivityState? state;

  @override
  Widget build(BuildContext context) {
    return CollapsingBannerSlot(
      child: state == null ? null : _ConnectivityBannerContent(state: state!),
    );
  }
}

class _ConnectivityBannerContent extends StatelessWidget {
  const _ConnectivityBannerContent({required this.state});

  final ConnectivityState state;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final theme = context.theme;
    final brand = theme.brand;
    final (Color roleColor, bool pulsing, String message) = switch (state) {
      ConnectivityState.offline => (
        brand.destructive,
        true,
        translations.connectivity.offline,
      ),
      ConnectivityState.limited => (brand.warning, true, translations.connectivity.limited),
      ConnectivityState.online => (brand.success, false, translations.connectivity.online),
    };
    final fillOpacity = theme.colors.brightness == Brightness.dark ? 0.20 : 0.10;

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Container(
            key: const ValueKey('connectivity-banner'),
            width: double.infinity,
            decoration: BoxDecoration(
              // Status is always soft: the role color as a 10% fill (20% in
              // dark), never a solid colored background. The hairline in the
              // role color separates the notice from the page below it. The
              // fill is blended over the theme background so it stays opaque:
              // the banner strip sits above routed content, where nothing
              // paints the page background behind it.
              color: Color.alphaBlend(
                roleColor.withValues(alpha: fillOpacity),
                theme.colors.background,
              ),
              border: Border(
                bottom: BorderSide(color: roleColor.withValues(alpha: 0.4)),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.lg,
              vertical: context.spacing.sm,
            ),
            child: Row(
              children: [
                _LiveMarker(color: roleColor, pulsing: pulsing),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The brand's hollow ring marker standing in for a live connection state.
///
/// The marker is decorative; the Semantics label above carries the meaning.
/// While the state is actively degrading (offline) the marker gently pulses,
/// which stops for reduced motion.
class _LiveMarker extends StatefulWidget {
  const _LiveMarker({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_LiveMarker> createState() => _LiveMarkerState();
}

class _LiveMarkerState extends State<_LiveMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.deliberate,
  );
  bool _running = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync(bool enabled) {
    if (enabled && !_running) {
      _running = true;
      unawaited(_controller.repeat(reverse: true));
    } else if (!enabled && _running) {
      _running = false;
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(widget.pulsing && !MediaQuery.disableAnimationsOf(context));
  }

  @override
  void didUpdateWidget(covariant _LiveMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsing != widget.pulsing) {
      _sync(widget.pulsing && !MediaQuery.disableAnimationsOf(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final marker = AppRingMarker(color: widget.color);
    if (!_running) {
      return marker;
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: marker,
    );
  }
}
