import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// A persistent connectivity banner mounted above the router child in
/// `MaterialApp.router`'s `builder:`.
///
/// Surfaces a full-width row for degraded states ([ConnectivityState.offline] /
/// [ConnectivityState.limited]) and fires a transient "back online" toast on the
/// recovery edge (degraded → [ConnectivityState.online]). Auth and onboarding
/// are top-level routes outside `AppShell`; mounting here keeps the signal alive
/// across every route. No widget reads `connectivity_plus` directly — the banner
/// watches [connectivityStatusProvider], which reads the port.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  @override
  void initState() {
    super.initState();
    // Detect the degraded → online recovery edge and fire the transient toast.
    // Not in build: build must stay free of side effects.
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
    showFToast(
      context: context,
      icon: Icon(
        FLucideIcons.wifi,
        size: 18,
        color: context.theme.colors.primary,
        semanticLabel: translations.connectivity.online,
      ),
      title: Text(translations.connectivity.backOnline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectivityStatusProvider).value;
    final showBanner = state != null && state.isDegraded;
    final mediaQuery = MediaQuery.of(context);
    // The banner row consumes the top safe-area inset via its own SafeArea;
    // zero it for the router child so its Scaffold does not double-pad below the
    // banner. When the banner is hidden the inset passes through unchanged.
    final childMediaQuery = showBanner
        ? mediaQuery.copyWith(padding: mediaQuery.padding.copyWith(top: 0))
        : mediaQuery;

    return Column(
      children: [
        _BannerSlot(state: showBanner ? state : null),
        Expanded(
          child: MediaQuery(
            data: childMediaQuery,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// The animated banner slot — renders the row for degraded states and an empty
/// zero-height placeholder otherwise. Enter/exit motion is sourced from
/// [AppMotion] and guarded by [MediaQuery.disableAnimationsOf] with a
/// non-animated fallback that still toggles visibility.
class _BannerSlot extends StatelessWidget {
  const _BannerSlot({required this.state});

  final ConnectivityState? state;

  @override
  Widget build(BuildContext context) {
    final content = state == null
        ? const SizedBox(width: double.infinity, height: 0)
        : _ConnectivityBannerContent(state: state!);

    if (MediaQuery.disableAnimationsOf(context)) {
      // Non-animated fallback: visibility still toggles, just instantly.
      return content;
    }
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: content,
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
        // Unreachable: the banner only renders for degraded states. The
        // case keeps the switch exhaustive over [ConnectivityState].
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

/// An opacity-pulsing status icon for the offline state.
///
/// Motion-guarded: the pulse runs only when [MediaQuery.disableAnimationsOf] is
/// false; otherwise a static icon renders. The pulse duration is sourced from
/// [AppMotion] so it tracks the shared motion vocabulary.
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
      // TickerFuture is intentionally fire-and-forget for a repeating pulse.
      unawaited(_controller.repeat(reverse: true));
    } else if (!enabled && _running) {
      _running = false;
      _controller.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Drive the pulse from the lifecycle, not build(): TickerMode / MediaQuery
    // changes re-run this callback, so enable/disable stays in sync without
    // mutating the _running field or starting/stopping the ticker during build.
    // Performing that side effect in build() is a fragile anti-pattern that a
    // future refactor could turn into a setState/markNeedsBuild-during-build
    // assertion. The static fallback value is unchanged.
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
