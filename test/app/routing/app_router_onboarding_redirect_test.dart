import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('fresh install boots to onboarding instead of home (cold-start redirect)', (
    tester,
  ) async {
    await _pumpApp(tester, _freshInstallDependencies());

    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-greeting')), findsNothing);
  });

  testWidgets('returning user (flag already complete) boots straight to home', (tester) async {
    await _pumpApp(
      tester,
      _dependencies(
        initialSettings: const SettingsState.defaults().copyWith(hasCompletedOnboarding: true),
      ),
    );

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('in-session Skip marks onboarding complete and reaches home WITHOUT a '
      'relaunch (regresses the captured-bool loop)', (tester) async {
    await _pumpApp(tester, _freshInstallDependencies());
    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('onboarding-skip'));
    await _pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('paywall Skip marks onboarding complete and reaches home in-session', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.onboardingPaywallPath,
    );
    expect(find.byKey(const ValueKey('paywall-skip')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('paywall-skip'));
    await _pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('paywall Continue marks onboarding complete and reaches home in-session', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.onboardingPaywallPath,
    );
    expect(find.byKey(const ValueKey('paywall-continue')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('paywall-continue'));
    await _pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('fresh-install deep link to /pricing redirects to onboarding', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.pricingPath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('pricing-page')), findsNothing);
  });

  testWidgets('fresh-install deep link to /settings redirects to onboarding', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.settingsPath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
  });

  testWidgets('already on onboarding: no redirect loop (onboarding routes are excluded '
      'from the gate)', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.onboardingPath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-greeting')), findsNothing);
  });

  testWidgets('auth routes are not hijacked by the onboarding gate on fresh install', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.loginPath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('detail routes reachable from the shell do not redirect independently', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.updateProfilePath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('after markOnboardingComplete + relaunch (reload from the same store), '
      'boots straight to home', (tester) async {
    final store = InMemorySettingsStore();

    await _pumpApp(
      tester,
      _dependencies(store: store),
    );
    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('onboarding-skip'));
    await _pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(store.snapshot[SettingsRepository.onboardingKey], 'true');

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpAppFrames(tester);

    final reloadedSettings = await SettingsRepository(store).load();
    expect(reloadedSettings.hasCompletedOnboarding, isTrue);

    await _pumpApp(
      tester,
      _dependencies(store: store, initialSettings: reloadedSettings),
    );

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });
}

final _productionConfig = AppConfig(
  environment: AppEnvironment.production,
  enableVerboseLogging: false,
  enableDevTools: false,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

AppDependencies _freshInstallDependencies() => _dependencies();

AppDependencies _dependencies({
  SettingsState? initialSettings,
  InMemorySettingsStore? store,
}) {
  final settingsStore = store ?? InMemorySettingsStore();
  return AppDependencies.inMemory(
    settingsStore: settingsStore,
    initialSettings: initialSettings ?? const SettingsState.defaults(),
    dismissedAnnouncementIds: AnnouncementFixtures.standard.map((a) => a.id).toSet(),
  );
}

Future<void> _pumpApp(
  WidgetTester tester,
  AppDependencies dependencies, {
  String initialLocation = AppRoutes.homePath,
}) async {
  await tester.pumpWidget(
    App(
      config: _productionConfig,
      dependencies: dependencies,
      initialLocation: initialLocation,
    ),
  );
  await _pumpAppFrames(tester);
}

/// Avoid pumpAndSettle: focused editables/animations schedule frames indefinitely.
Future<void> _pumpAppFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  tester.binding.focusManager.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(target);
  await _pumpAppFrames(tester);
  await tester.tap(target.hitTestable());
  await _pumpAppFrames(tester);
}
