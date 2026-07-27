import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/startup/startup_error_view.dart';
import 'package:starter/features/splash/app_startup_result.dart';
import 'package:starter/features/splash/app_startup_result_provider.dart';
import 'package:starter/features/splash/splash_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// The animated in-app splash screen.
///
/// Watches the existing init future exposed by [appStartupResultProvider] and
/// hands off to the router (home / onboarding) the moment it resolves. The
/// splash is a presentation wrapper over work the composition root already
/// performs — it never re-runs settings, locale, or package_info load (the
/// canonical splash mistake). The branded reveal and spinner are cosmetic;
/// navigation is **never** gated on their completion (audit checklist #5).
///
/// The page receives a navigation callback rather than calling `go_router`
/// directly, consistent with the root integration contract. The router's
/// `onComplete` performs `context.goNamed(home)`; the existing C5 redirect then
/// sends fresh installs to onboarding transparently.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    required this.onComplete,
    super.key,
  });

  /// Invoked exactly once with the resolved startup result. The router uses this
  /// to navigate to home (the onboarding/force-update redirects compose in the
  /// existing C5 helper).
  final void Function(AppStartupResult result) onComplete;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    // Listen for the resolved future and hand off. fireImmediately covers the
    // common case where createApplication completes before the widget mounts.
    // The handoff is deferred to the next frame (a frame, NOT an animation
    // completion) so the router is never mutated mid-build; under the bounded
    // pumpAppFrames (8 frames) harness it fires on frame 1 regardless of the
    // logo reveal's progress.
    ref.listenManual<AsyncValue<AppStartupResult>>(
      appStartupResultProvider,
      (_, next) {
        if (!mounted || _handedOff) {
          return;
        }
        if (next case AsyncData(:final value)) {
          _handedOff = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onComplete(value);
            }
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appStartupResultProvider);
    final viewData = switch (async) {
      AsyncData(:final value) => SplashViewData.fromResult(value),
      AsyncError(:final error) => SplashViewData(
        phase: SplashPhase.error,
        errorDiagnosticId: startupDiagnosticIdFor(error),
      ),
      AsyncLoading() => SplashFixtures.loading,
    };
    return SplashScene(viewData: viewData);
  }
}

/// The branded splash visual for a fixed [SplashViewData]. Public so the
/// development gallery can compose deterministic loading / done / error
/// previews without the async provider; the production [SplashPage] renders it
/// from the watched future. Motion is sourced from [AppMotion] and guarded with
/// [MediaQuery.disableAnimationsOf] plus a non-animated fallback.
class SplashScene extends StatelessWidget {
  const SplashScene({required this.viewData, super.key});

  final SplashViewData viewData;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.theme.colors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: switch (viewData.phase) {
              SplashPhase.loading => _SplashLoading(viewData: viewData),
              SplashPhase.done => _SplashDone(viewData: viewData),
              SplashPhase.error => _SplashError(viewData: viewData),
            },
          ),
        ),
      ),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading({required this.viewData});

  final SplashViewData viewData;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LogoReveal(child: _BrandMark()),
        const SizedBox(height: AppSpacing.xl),
        Text(
          translations.app.name,
          key: const ValueKey('splash-title'),
          style: context.theme.typography.display.xl2,
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
          child: Text(
            translations.splash.tagline,
            key: const ValueKey('splash-tagline'),
            style: context.theme.typography.body.lg,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        if (reduceMotion)
          Text(
            translations.splash.loading,
            key: const ValueKey('splash-loading-label'),
            style: context.theme.typography.body.md,
          )
        else
          const _Spinner(),
      ],
    );
  }
}

class _SplashDone extends StatelessWidget {
  const _SplashDone({required this.viewData});

  final SplashViewData viewData;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandMark(),
        const SizedBox(height: AppSpacing.lg),
        Icon(
          FLucideIcons.circleCheck,
          size: 32,
          color: context.theme.colors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          translations.app.name,
          style: context.theme.typography.display.xl2,
        ),
        if (viewData.buildLabel case final label?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            key: const ValueKey('splash-build-label'),
            style: context.theme.typography.body.sm,
          ),
        ],
      ],
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.viewData});

  final SplashViewData viewData;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            FLucideIcons.triangleAlert,
            size: 40,
            color: context.theme.colors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            translations.splash.error,
            key: const ValueKey('splash-error'),
            style: context.theme.typography.display.xl,
            textAlign: TextAlign.center,
          ),
          if (viewData.errorDiagnosticId case final id?) ...[
            const SizedBox(height: AppSpacing.lg),
            SelectableText(
              translations.startupFailure.diagnosticId(id: id),
              key: const ValueKey('splash-diagnostic-id'),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A circular brand placeholder. Real brand assets replace this glyph without
/// touching the surrounding layout.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.theme.colors.primary,
      ),
      alignment: Alignment.center,
      child: Icon(
        FLucideIcons.sparkles,
        size: 44,
        color: context.theme.colors.primaryForeground,
      ),
    );
  }
}

/// A small indeterminate activity indicator for the loading phase.
class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(context.theme.colors.primary),
      ),
    );
  }
}

/// A one-shot logo reveal: opacity 0 -> 1 and scale 0.92 -> 1 over
/// [AppMotion.deliberate] with the emphasized curve. Motion-guarded: under
/// [MediaQuery.disableAnimationsOf] the child renders statically (fully
/// revealed) and the controller never runs. The reveal is purely cosmetic —
/// navigation is driven by [SplashPage] and never waits on this animation.
class _LogoReveal extends StatefulWidget {
  const _LogoReveal({required this.child});

  final Widget child;

  @override
  State<_LogoReveal> createState() => _LogoRevealState();
}

class _LogoRevealState extends State<_LogoReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.deliberate,
  );
  late final Animation<double> _fade = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: AppMotion.standardCurve),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: AppMotion.emphasizedCurve),
  );
  bool _started = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync(bool animate) {
    if (_started) {
      return;
    }
    _started = true;
    if (animate) {
      unawaited(_controller.forward());
    } else {
      // Reduced motion: jump straight to the revealed end state.
      _controller.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    _sync(!MediaQuery.disableAnimationsOf(context));
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
