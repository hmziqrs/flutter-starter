import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/banners/collapsing_banner_slot.dart';
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
    final showBanner = state != null && state.isDegraded;
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
    final (Color background, Color foreground, IconData icon, String message) = switch (state) {
      ConnectivityState.offline => (
        context.theme.colors.error,
        context.theme.colors.errorForeground,
        FLucideIcons.wifiOff,
        translations.connectivity.offline,
      ),
      ConnectivityState.limited => (
        context.theme.colors.secondary,
        context.theme.colors.secondaryForeground,
        FLucideIcons.wifiLow,
        translations.connectivity.limited,
      ),
      ConnectivityState.online => (
        context.theme.colors.background,
        context.theme.colors.foreground,
        FLucideIcons.wifi,
        translations.connectivity.online,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Material(
        color: background,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (state == ConnectivityState.offline)
                  _PulsingIcon(icon: icon, color: foreground)
                else
                  Icon(icon, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: context.theme.typography.body.sm.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
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

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
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
    _sync(!MediaQuery.disableAnimationsOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon, size: 18, color: widget.color);
    if (!_running) {
      return icon;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: 0.45 + 0.55 * _controller.value,
        child: child,
      ),
      child: icon,
    );
  }
}
