import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('Onboarding Skip reaches Home', (tester) async {
    await _pumpApp(tester, AppRoutes.onboardingPath);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('Onboarding final Continue opens Paywall and its Skip reaches Home', (tester) async {
    await _pumpApp(tester, AppRoutes.onboardingPath);

    for (var index = 0; index < 3; index += 1) {
      await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('paywall-page')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('paywall-skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('Paywall static Continue reaches Home without claiming a purchase', (tester) async {
    await _pumpApp(tester, AppRoutes.onboardingPaywallPath);

    expect(find.text('No payment or purchase will be made.'), findsOneWidget);
    final continueButton = find.byKey(const ValueKey('paywall-continue'));
    await tester.ensureVisible(continueButton);
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('Home quick actions reach their centrally wired destinations', (tester) async {
    const cases = [
      (source: 'home-open-profile', target: 'profile-save'),
      (source: 'home-open-pricing', target: 'pricing-page'),
      (source: 'home-open-settings', target: 'settings-open-appearance'),
      (source: 'home-open-login', target: 'auth-login-page'),
    ];

    for (final entry in cases) {
      // /profile/edit is auth-required (C5 session gate); seed an authenticated
      // session so the quick action is not bounced to /auth/login.
      await _pumpApp(
        tester,
        AppRoutes.homePath,
        initialSession: entry.source == 'home-open-profile' ? _authenticatedSession : null,
      );
      final source = find.byKey(ValueKey(entry.source));
      await tester.ensureVisible(source);
      await tester.pumpAndSettle();
      await tester.tap(source);
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey(entry.target)), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Profile save provides honest deterministic feedback', (tester) async {
    await _pumpApp(
      tester,
      AppRoutes.updateProfilePath,
      initialSession: _authenticatedSession,
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-bio')),
      'Updated locally for the static preview.',
    );
    await _tapVisible(tester, 'profile-save');

    expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);
    expect(find.text('This action is not connected yet.'), findsOneWidget);
  });

  testWidgets('Login surfaces honest globalFailure with no backend (C13)', (tester) async {
    await _pumpApp(tester, AppRoutes.loginPath);
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-email')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      'Password1',
    );
    await _tapVisible(tester, 'auth-login-submit');

    // The no-backend default (InMemoryAuthRepository.login) throws
    // AuthException.notConnected — the page surfaces globalFailure honestly
    // rather than navigating to Home as if authentication succeeded (C13).
    expect(find.byKey(const ValueKey('auth-login-global-failure')), findsOneWidget);
  });

  testWidgets('Login engages the auth-ratelimit lockout after repeated failures (C1)', (
    tester,
  ) async {
    await _pumpApp(tester, AppRoutes.loginPath);
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-email')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-password')),
      'Password1',
    );

    // The no-backend InMemoryAuthRepository throws AuthException on every call.
    // The default schedule [0, 0, 30, ...] grants two free attempts, then locks
    // for 30s on the third failure. The shared AttemptTracker is the same one
    // the OTP surface consumes, so this is the login-named-consumer wiring the
    // auth-ratelimit spec requires (login, OTP, pin-autolock = 3 consumers).
    for (var attempt = 1; attempt <= 2; attempt++) {
      await _tapVisible(tester, 'auth-login-submit');
      expect(
        find.byKey(const ValueKey('auth-login-global-failure')),
        findsOneWidget,
        reason: 'attempt $attempt is still within the free allowance',
      );
    }

    // Third failure escalates to a 30s lockout. Tap + bounded pumps (NOT
    // pumpAndSettle) because the lockout Timer.periodic fires every 1s and
    // would otherwise keep pumpAndSettle alive past its timeout.
    final submit = find.byKey(const ValueKey('auth-login-submit'));
    await tester.ensureVisible(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const ValueKey('auth-login-locked')), findsOneWidget);
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('auth-login-submit'))).onPress,
      isNull,
      reason: 'submit is disabled while the lockout countdown is active',
    );

    // Expire the 30s lockout so the countdown Timer.periodic self-cancels and
    // the test binding's no-pending-timers invariant holds at teardown.
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('Register surfaces honest notConnected with no backend (C13)', (tester) async {
    await _pumpApp(tester, AppRoutes.registerPath);
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-display-name')),
      'Sam Rivera',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-email')),
      'sam@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-password')),
      'Password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-confirm-password')),
      'Password1',
    );
    await _tapVisible(tester, 'auth-register-accept-terms');
    await _tapVisible(tester, 'auth-register-submit');

    // Registration is backend-dependent; the no-backend default surfaces
    // common.notConnected rather than navigating to OTP as if the account was
    // created (C13).
    expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);
    expect(find.text('This action is not connected yet.'), findsOneWidget);
  });

  testWidgets('Forgot Password follows reset OTP to Login success feedback', (tester) async {
    await _pumpApp(tester, AppRoutes.forgotPasswordPath);
    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-password-email')),
      'person@example.com',
    );
    await _tapVisible(tester, 'auth-forgot-password-submit');

    expect(find.text('Verify your reset request'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('auth-otp-code')),
      '654321',
    );
    await _tapVisible(tester, 'auth-otp-submit');

    expect(find.byKey(const ValueKey('auth-reset-password-page')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('auth-reset-password-new')),
      'Password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-reset-password-confirm')),
      'Password1',
    );
    await _tapVisible(tester, 'auth-reset-password-submit');

    final login = find.byKey(const ValueKey('auth-login-page'));
    expect(login, findsOneWidget);
    expect(find.byKey(const ValueKey('auth-login-success')), findsOneWidget);
    expect(
      find.text('Password update preview complete. Return to login.'),
      findsOneWidget,
    );
    expect(
      GoRouter.of(tester.element(login)).canPop(),
      isFalse,
      reason: 'a directly opened reset flow must finish on a root Login',
    );
  });
}

Future<void> _tapVisible(WidgetTester tester, String valueKey) async {
  final target = find.byKey(ValueKey(valueKey));
  tester.binding.focusManager.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _pumpApp(
  WidgetTester tester,
  String initialLocation, {
  AuthSession? initialSession,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    App(
      config: _productionConfig,
      dependencies: AppDependencies.inMemory(
        initialSession: initialSession,
        // The floating announcement banner overlaps the top of the screen; dismiss
        // the whole feed so it never occludes the routing targets these cases tap.
        dismissedAnnouncementIds: AnnouncementFixtures.standard.map((a) => a.id).toSet(),
      ),
      initialLocation: initialLocation,
    ),
  );
  await tester.pumpAndSettle();
}

final _productionConfig = AppConfig(
  environment: AppEnvironment.production,
  enableVerboseLogging: false,
  enableDevTools: false,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

/// Seeded authenticated session for auth-required destinations (/profile/edit,
/// C5 session gate). Deterministic placeholders; the gate checks isAuthenticated.
final _authenticatedSession = AuthAuthenticated(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  expiresAt: DateTime.utc(9999, 12, 31),
  userId: 'test-user',
);
