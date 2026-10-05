import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';

import 'integration_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester, AppConfig config) async {
    await tester.pumpWidget(
      await createApplication(
        config,
        secureStore: InMemorySecureStore(),
        connectivityService: const StaticConnectivityService(),
      ),
    );
    await pumpAppFrames(tester);
  }

  testWidgets('a persisted last route re-opens through createApplication', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);

    await resetTestSettings();
    addTearDown(resetTestSettings);
    final store = SharedPreferencesSettingsStore();
    await store.writeString(lastRouteKey, AppRoutes.pricingPath);

    await pumpApp(tester, config);

    expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-greeting')), findsNothing);
  });

  testWidgets('the onboarding gate wins over a persisted last route', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);

    await resetTestSettings();
    addTearDown(resetTestSettings);
    final store = SharedPreferencesSettingsStore();
    await store.writeString(SettingsRepository.onboardingKey, 'false');
    await store.writeString(lastRouteKey, AppRoutes.pricingPath);

    await pumpApp(tester, config);

    expect(find.byKey(const ValueKey('onboarding-pager')), findsOneWidget);
    expect(find.byKey(const ValueKey('pricing-page')), findsNothing);
  });
}
