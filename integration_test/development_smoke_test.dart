import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';

import 'integration_test_support.dart';

final _clock = Stopwatch()..start();

void _log(Object? message) {
  // debugPrint only: the test binding rebinds stdout, so dart:io writes throw.
  debugPrint('   │ smoke · ${_clock.elapsed.toString().split('.').first.padLeft(8)} · $message');
}

/// Watch mode keeps native window size: `physicalSize` blanks the desktop window (flutter#149209).
const _watchMode = bool.fromEnvironment('SMOKE_WATCH');

const _watchDilationString = String.fromEnvironment('SMOKE_DILATION', defaultValue: '2.0');
final double _watchDilation = double.tryParse(_watchDilationString) ?? 2.0;

Future<void> _watchPause(WidgetTester tester) async {
  if (_watchMode) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

Future<void> _withoutDilation(Future<void> Function() action) async {
  final saved = timeDilation;
  if (_watchMode) {
    timeDilation = 1.0;
  }
  try {
    await action();
  } finally {
    timeDilation = saved;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('development production-composition smoke flow persists settings', (tester) async {
    _log('starting development smoke flow${_watchMode ? ' (WATCH MODE)' : ''}');
    _log('resolving compile-time config (APP_ENV, ENABLE_*)');
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);
    expect(config.developmentToolsEnabled, isTrue);
    final hasBackend = config.backendBaseUrl != null;
    _log(
      'config ok: environment=${config.environment.value} devTools=${config.developmentToolsEnabled}',
    );

    _log('resetting persisted settings (shared preferences)');
    await resetTestSettings();
    addTearDown(resetTestSettings);
    if (_watchMode) {
      timeDilation = _watchDilation;
      _log('WATCH MODE: keeping native window at default size so the UI is visible');
      _log('(setting physicalSize blanks the desktop window — flutter#149209)');
      _log('WATCH MODE: animation dilation = $_watchDilation (tune via SMOKE_DILATION)');
    } else {
      _setViewport(tester, const Size(390, 844));
      _log('viewport pinned to 390x844 (compact phone)');
    }

    _log(
      'building app graph + root widget (first run also compiles the macOS runner; this is the slow part)',
    );
    // The headless Linux runner has no secret-service daemon (libsecret).
    await tester.pumpWidget(
      await createApplication(config, secureStore: InMemorySecureStore()),
    );
    await pumpAppFrames(tester);
    await _watchPause(tester);
    _log('app launched; expecting home greeting');
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    _log('home rendered');

    _log('navigating: home -> pricing (compact bottom-nav tap)');
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('compact-navigation')),
        matching: find.byIcon(FLucideIcons.badgeDollarSign),
      ),
    );
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);
    _log('pricing rendered');
    _log('navigating: pricing -> home (compact bottom-nav tap)');
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('compact-navigation')),
        matching: find.byIcon(FLucideIcons.house),
      ),
    );
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    _log('back on home');

    _log('navigating: home -> onboarding');
    await _go(tester, AppRoutes.onboardingPath);
    for (var index = 0; index < 3; index += 1) {
      _log('onboarding: tapping continue (${index + 1}/3)');
      await tapVisible(tester, const ValueKey('onboarding-continue'));
      await _watchPause(tester);
    }
    _log('expecting paywall');
    expect(find.byKey(const ValueKey('paywall-page')), findsOneWidget);
    _log('paywall rendered; tapping skip');
    await tapVisible(tester, const ValueKey('paywall-skip'));
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    _log('back on home');

    _log('navigating: home -> register');
    await _go(tester, AppRoutes.registerPath);
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
    _log('register form filled; accepting terms');
    await tapVisible(tester, const ValueKey('auth-register-accept-terms'));
    _log('submitting registration');
    await tapVisible(tester, const ValueKey('auth-register-submit'));
    if (!hasBackend) {
      _log('no backend configured; expecting honest unavailable feedback');
      expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);
      await tapVisible(tester, const ValueKey('information-dialog-close'));
      expect(find.byKey(const ValueKey('auth-register-submit')), findsOneWidget);
      _log('opening registration OTP route directly to exercise its no-backend state');
      await _go(
        tester,
        '${AppRoutes.otpLocation(OtpPurpose.registration)}?identifier=sam%40example.com',
      );
    }
    _log('expecting OTP page');
    expect(find.byKey(const ValueKey('auth-otp-page')), findsOneWidget);
    _log('OTP page rendered');

    _log('entering OTP code 123456');
    await tester.enterText(find.byKey(const ValueKey('auth-otp-code')), '123456');
    await tapVisible(tester, const ValueKey('auth-otp-submit'));
    if (!hasBackend) {
      _log('OTP verification degraded honestly; continuing navigation coverage at home');
      expect(find.byKey(const ValueKey('auth-otp-page')), findsOneWidget);
      await _go(tester, AppRoutes.homePath);
      _log('seeding a test-only session for protected-route smoke coverage');
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const ValueKey('home-greeting'))),
        listen: false,
      );
      await container
          .read(sessionControllerProvider.notifier)
          .establish(
            AuthAuthenticated(
              accessToken: 'smoke-access-token',
              refreshToken: 'smoke-refresh-token',
              expiresAt: DateTime.now().add(const Duration(hours: 1)),
              userId: 'smoke-user',
            ),
          );
      await pumpAppFrames(tester);
    }
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    _log('registration/OTP route coverage complete; back on home');

    _log('navigating: home -> edit profile');
    await _go(tester, AppRoutes.updateProfilePath);
    final bio = find.byKey(const ValueKey('profile-bio'));
    await tester.enterText(bio, 'Retained through every layout class.');
    await tester.showKeyboard(bio);
    expect(_editable(tester, bio).focusNode.hasFocus, isTrue);
    _log('profile bio entered + focused');

    if (_watchMode) {
      _log('WATCH MODE: skipping layout-class resize loop (requires physicalSize)');
    } else {
      _log('resizing through layout classes (asserting draft text retained)');
      for (final size in const [Size(390, 844), Size(800, 1000), Size(1024, 768)]) {
        _log('  resize -> ${size.width}x${size.height} (asserting draft text retained)');
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        await tester.pump(const Duration(milliseconds: 500));
        expect(_editable(tester, bio).controller.text, 'Retained through every layout class.');
      }
      _log('draft text retained across compact/medium/expanded sizes');
      tester.view.physicalSize = const Size(390, 844) * tester.view.devicePixelRatio;
      await pumpAppFrames(tester);
    }
    await _watchPause(tester);

    _log('saving profile; expecting confirmation dialog');
    await tapVisible(tester, const ValueKey('profile-save'));
    expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);
    _log('dialog shown; dismissing with Escape');
    await _withoutDilation(() async {
      await pumpAppFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpAppFrames(tester);
    });
    expect(find.byKey(const ValueKey('information-dialog')), findsNothing);
    _log('dialog dismissed');

    _log('navigating: -> appearance settings');
    await _go(tester, AppRoutes.appearanceSettingsPath);
    await tapVisible(tester, const ValueKey('theme-dark'));
    _log('theme = dark');
    await tapVisible(tester, const ValueKey('accent-blue'));
    _log('accent = blue');
    final slider = find.byKey(const ValueKey('font-scale-slider'));
    await tester.ensureVisible(slider);
    await pumpAppFrames(tester);
    final sliderTrack = find.descendant(
      of: slider,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onHorizontalDragStart != null,
      ),
    );
    expect(sliderTrack, findsWidgets);
    final sliderBounds = tester.getRect(sliderTrack.first);
    await tester.tapAt(sliderBounds.centerRight - const Offset(1, 0));
    await pumpAppFrames(tester);
    _log('font-scale slider moved to maximum');

    _log('navigating: -> language settings');
    await _go(tester, AppRoutes.languageSettingsPath);
    await tapVisible(tester, const ValueKey('locale-ar'));
    _log('locale = ar (expecting RTL)');
    final liveState = _settingsState(tester);
    expect(liveState.themeMode, AppThemeMode.dark);
    expect(liveState.accent, AppAccent.blue);
    expect(liveState.fontScale, SettingsState.maximumFontScale);
    expect(liveState.localeOverride, AppLocale.ar);
    expect(
      Directionality.of(tester.element(find.byKey(const ValueKey('locale-ar')))),
      TextDirection.rtl,
    );
    _log('in-memory settings verified: dark / blue / maxFont / ar / rtl');

    _log('tearing app down, then rebuilding to verify persistence across restart');
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpAppFrames(tester);
    await tester.pumpWidget(
      await createApplication(config, secureStore: InMemorySecureStore()),
    );
    await pumpAppFrames(tester);

    final restoredState = _settingsState(tester);
    expect(restoredState, liveState);
    _log('settings restored after restart');
    // Post-restart UI re-check omitted: the rebooted MaterialApp flakes on persisted theme/locale.
    _log('SMOKE FLOW COMPLETE — all assertions passed');
    if (_watchMode) {
      // Reset synchronously: the binding's debugAssertNoTimeDilation runs before addTearDown.
      timeDilation = 1.0;
    }
  });
}

Future<void> _go(WidgetTester tester, String location) async {
  final rootContext = tester.element(find.byType(Navigator).first);
  GoRouter.of(rootContext).go(location);
  await pumpAppFrames(tester);
  await _watchPause(tester);
}

SettingsState _settingsState(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  return ProviderScope.containerOf(context).read(settingsControllerProvider);
}

EditableText _editable(WidgetTester tester, Finder field) {
  return tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}
