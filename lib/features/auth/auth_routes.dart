import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/forgot_password_page.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
import 'package:starter/features/auth/otp_controller.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/features/auth/register_page.dart';
import 'package:starter/features/auth/reset_password_page.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/widgets/feedback/legal_dialog_callbacks.dart';

List<RouteBase> buildAuthRoutes() => [
  GoRoute(
    name: AppRoutes.login,
    path: AppRoutes.loginPath,
    builder: (context, state) => LoginRoutePage(
      passwordResetComplete: state.uri.queryParameters['status'] == _passwordResetComplete,
    ),
  ),
  GoRoute(
    name: AppRoutes.register,
    path: AppRoutes.registerPath,
    builder: (context, state) {
      final legal = legalDialogCallbacks(
        context,
        termsTitle: context.t.auth.register.terms,
        privacyTitle: context.t.auth.register.privacy,
      );
      return RegisterPage(
        onSubmit: (value) async {
          final container = ProviderScope.containerOf(context, listen: false);
          try {
            await container
                .read(authRepositoryProvider)
                .register(
                  credentials: AuthCredentials(email: value.email, password: value.password),
                  displayName: value.displayName,
                );
            if (!context.mounted) return;
            GoRouter.of(context).goNamed(
              AppRoutes.otp,
              pathParameters: <String, String>{
                'purpose': OtpPurpose.registration.pathSegment,
              },
              queryParameters: <String, String>{'identifier': value.email},
            );
          } on AuthException {
            if (!context.mounted) return;
            showAppInformationDialog(
              context,
              title: context.t.common.legalPlaceholderTitle,
              body: context.t.common.notConnected,
            );
          }
        },
        onLogin: () => _returnToLogin(context),
        onOpenTerms: legal.onOpenTerms,
        onOpenPrivacy: legal.onOpenPrivacy,
      );
    },
  ),
  GoRoute(
    name: AppRoutes.forgotPassword,
    path: AppRoutes.forgotPasswordPath,
    builder: (context, state) => ForgotPasswordPage(
      onSubmit: (_) => unawaited(_openPasswordResetOtp(context)),
      onLogin: () => _finishPasswordResetFlow(
        context,
        _PasswordResetFlowResult.returnToLogin,
      ),
    ),
  ),
  GoRoute(
    name: AppRoutes.otp,
    path: AppRoutes.otpPath,
    builder: (context, state) {
      final purpose = OtpPurpose.tryParse(state.pathParameters['purpose']);
      if (purpose == null) {
        return buildRouteErrorPage(
          context,
          state,
          message: context.t.routeError.invalidOtpPurpose,
        );
      }
      if (purpose == OtpPurpose.mfa || purpose == OtpPurpose.registration) {
        return OtpRoutePage(
          purpose: purpose,
          identifier: state.uri.queryParameters['identifier'] ?? '',
        );
      }
      return OtpPage(
        purpose: purpose,
        onSubmit: (_) => switch (purpose) {
          OtpPurpose.registration => context.goNamed(AppRoutes.home),
          OtpPurpose.passwordReset => unawaited(_openResetPassword(context)),
          OtpPurpose.mfa => context.goNamed(AppRoutes.home),
        },
        onResend: () => showAppInformationDialog(
          context,
          title: context.t.auth.otp.resend,
          body: context.t.common.notConnected,
        ),
      );
    },
  ),
  GoRoute(
    name: AppRoutes.resetPassword,
    path: AppRoutes.resetPasswordPath,
    builder: (context, state) => ResetPasswordPage(
      onSubmit: (_) => _finishPasswordResetFlow(
        context,
        _PasswordResetFlowResult.completed,
      ),
      onLogin: () => _finishPasswordResetFlow(
        context,
        _PasswordResetFlowResult.returnToLogin,
      ),
    ),
  ),
];

const _passwordResetComplete = 'password-reset-complete';

enum _PasswordResetFlowResult {
  completed,
  returnToLogin,
}

class LoginRoutePage extends ConsumerStatefulWidget {
  const LoginRoutePage({required this.passwordResetComplete, super.key});

  final bool passwordResetComplete;

  @override
  ConsumerState<LoginRoutePage> createState() => _LoginRoutePageState();
}

class _LoginRoutePageState extends ConsumerState<LoginRoutePage> {
  late bool _passwordResetComplete = widget.passwordResetComplete;
  LoginPresentationStatus _status = LoginPresentationStatus.idle;
  int _lockedSeconds = 0;
  int _attemptsRemaining = 0;

  @override
  void didUpdateWidget(covariant LoginRoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passwordResetComplete != oldWidget.passwordResetComplete) {
      _passwordResetComplete = widget.passwordResetComplete;
    }
  }

  LoginPresentationState _presentation() {
    if (_passwordResetComplete) {
      return LoginPresentationState.success(
        successMessage: context.t.auth.resetPassword.success,
      );
    }
    return switch (_status) {
      LoginPresentationStatus.locked => LoginPresentationState.locked(
        lockedSeconds: _lockedSeconds,
        attemptsRemaining: _attemptsRemaining,
      ),
      _ => LoginPresentationState(
        status: _status,
        attemptsRemaining: _attemptsRemaining,
      ),
    };
  }

  Future<void> _openForgotPassword() async {
    final result = await context.pushNamed<_PasswordResetFlowResult>(
      AppRoutes.forgotPassword,
    );
    if (!mounted || result != _PasswordResetFlowResult.completed) {
      return;
    }
    setState(() => _passwordResetComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      presentation: _presentation(),
      onSubmit: (value) async {
        final router = GoRouter.of(context);
        final tracker = ref.read(attemptTrackerProvider);
        final existing = tracker.read(value.email);
        final now = clock.now();
        if (existing != null && existing.isLockedAt(now)) {
          if (!mounted) return;
          setState(() {
            _status = LoginPresentationStatus.locked;
            _lockedSeconds = existing.lockedSecondsAt(now);
            _attemptsRemaining = existing.attemptsRemaining;
          });
          return;
        }
        setState(() => _status = LoginPresentationStatus.submitting);
        try {
          await ref
              .read(sessionControllerProvider.notifier)
              .login(
                AuthCredentials(email: value.email, password: value.password),
              );
          if (!mounted) return;
          final session = ref.read(sessionControllerProvider);
          if (session is AuthAuthenticated) {
            tracker.recordSuccess(value.email);
            router.goNamed(AppRoutes.home);
          } else {
            setState(() => _status = LoginPresentationStatus.globalFailure);
          }
        } on AuthException {
          if (!mounted) return;
          final attempt = tracker.recordFailure(value.email);
          final lockedNow = clock.now();
          setState(() {
            _attemptsRemaining = math.max(0, attempt.attemptsRemaining);
            _status = attempt.isLockedAt(lockedNow)
                ? LoginPresentationStatus.locked
                : LoginPresentationStatus.globalFailure;
            if (attempt.isLockedAt(lockedNow)) {
              _lockedSeconds = attempt.lockedSecondsAt(lockedNow);
            }
          });
        }
      },
      onForgotPassword: () => unawaited(_openForgotPassword()),
      onRegister: () => context.pushNamed(AppRoutes.register),
    );
  }
}

Future<void> _openPasswordResetOtp(BuildContext context) async {
  final result = await context.push<_PasswordResetFlowResult>(
    AppRoutes.otpLocation(OtpPurpose.passwordReset),
  );
  if (result != null && context.mounted) {
    _finishPasswordResetFlow(context, result);
  }
}

Future<void> _openResetPassword(BuildContext context) async {
  final result = await context.pushNamed<_PasswordResetFlowResult>(
    AppRoutes.resetPassword,
  );
  if (result != null && context.mounted) {
    _finishPasswordResetFlow(context, result);
  }
}

void _finishPasswordResetFlow(
  BuildContext context,
  _PasswordResetFlowResult result,
) {
  popOrGoNamed(
    context,
    AppRoutes.login,
    result: result,
    queryParameters: result == _PasswordResetFlowResult.completed
        ? const {'status': _passwordResetComplete}
        : const {},
  );
}

void _returnToLogin(BuildContext context) {
  popOrGoNamed(context, AppRoutes.login);
}

class OtpRoutePage extends ConsumerStatefulWidget {
  const OtpRoutePage({required this.purpose, required this.identifier, super.key});

  final OtpPurpose purpose;

  final String identifier;

  @override
  ConsumerState<OtpRoutePage> createState() => _OtpRoutePageState();
}

class _OtpRoutePageState extends ConsumerState<OtpRoutePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = (purpose: widget.purpose, identifier: widget.identifier);
      unawaited(ref.read(otpControllerProvider(key).notifier).requestIssue());
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = (purpose: widget.purpose, identifier: widget.identifier);
    final state = ref.watch(otpControllerProvider(key));
    final controller = ref.read(otpControllerProvider(key).notifier);
    return OtpPage(
      purpose: widget.purpose,
      presentation: state.presentation.copyWithRemainingSeconds(state.remainingSeconds),
      onSubmit: (value) async {
        final ok = await controller.verify(value.code);
        if (!ok || !mounted) {
          return;
        }
        if (widget.purpose == OtpPurpose.registration) {
          final session = ref.read(otpControllerProvider(key)).session;
          if (session != null) {
            await ref.read(sessionControllerProvider.notifier).establish(session);
            if (!mounted) return;
          }
        }
        // ignore: use_build_context_synchronously, after awaited establish() + mounted check
        context.goNamed(AppRoutes.home);
      },
      onResend: controller.resend,
    );
  }
}
