import 'dart:async';

import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/startup/startup_error_view.dart';
import 'package:starter/features/splash/app_startup_result.dart';
import 'package:starter/features/splash/app_startup_result_provider.dart';
import 'package:starter/features/splash/splash_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';
import 'package:starter/shared/widgets/rings/ring_loader.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    required this.onComplete,
    super.key,
  });

  final void Function(AppStartupResult result) onComplete;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
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
            padding: EdgeInsets.symmetric(horizontal: context.spacing.xl),
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
    final spacing = context.spacing;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoReveal(
            // Long translated names (ar) overflow a narrow viewport, so the
            // wordmark scales down instead of overflowing (same dependent
            // fix as the expanded shell sidebar).
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: AppWordmark(
                name: translations.app.name,
                fontSize: 28,
              ),
            ),
          ),
          SizedBox(height: spacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.presentationTokens.formContentMaxWidth),
            child: Text(
              translations.splash.tagline,
              key: const ValueKey('splash-tagline'),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: spacing.xl2),
          if (reduceMotion)
            Text(
              translations.splash.loading,
              key: const ValueKey('splash-loading-label'),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            )
          else
            // The brand's own loader: an orange arc sweeping a hairline
            // track, in the rings' language. A still quarter arc under
            // reduced motion.
            RingLoader(semanticsLabel: translations.splash.loading),
        ],
      ),
    );
  }
}

class _SplashDone extends StatelessWidget {
  const _SplashDone({required this.viewData});

  final SplashViewData viewData;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final spacing = context.spacing;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AppWordmark(name: translations.app.name, fontSize: 28),
          ),
          SizedBox(height: spacing.lg),
          Icon(
            FLucideIcons.circleCheck,
            size: 24,
            color: context.theme.brand.success,
          ),
          if (viewData.buildLabel case final label?) ...[
            SizedBox(height: spacing.sm),
            Text(
              label,
              key: const ValueKey('splash-build-label'),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.viewData});

  final SplashViewData viewData;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final spacing = context.spacing;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context.presentationTokens.formContentMaxWidth),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(
                FLucideIcons.octagonAlert,
                size: 24,
                color: context.theme.brand.destructive,
              ),
            ),
            SizedBox(height: spacing.lg),
            Text(
              translations.splash.error,
              key: const ValueKey('splash-error'),
              style: context.theme.typography.display.xl.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -(context.theme.typography.display.xl.fontSize ?? 24) * 0.02,
              ),
              textAlign: TextAlign.center,
            ),
            // BRAND.md s11: errors say what went wrong and how to fix it —
            // the same fix-it line the app-level StartupErrorView renders.
            SizedBox(height: spacing.md),
            Text(
              translations.startupFailure.body,
              key: const ValueKey('splash-error-body'),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            if (viewData.errorDiagnosticId case final id?) ...[
              SizedBox(height: spacing.lg),
              SelectableText(
                translations.startupFailure.diagnosticId(id: id),
                key: const ValueKey('splash-diagnostic-id'),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                  fontFamily: 'JetBrains Mono',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The splash opens with a fade only: openings may fade in, nothing scales or
/// moves (BRAND.md section 10). Reduced motion gets the settled picture.
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
      _controller.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    _sync(!MediaQuery.disableAnimationsOf(context));
    return FadeTransition(opacity: _fade, child: widget.child);
  }
}
