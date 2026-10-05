import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';

import 'integration_test_support.dart';

/// Home list adoption: skeleton→content behind the recent-activity load future,
/// and pull-to-refresh surfacing the backend-free `notConnected` toast. Bounded
/// frames only — never `pumpAndSettle`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home recent activity composes from skeleton bones into content', (tester) async {
    final config = AppConfig.fromEnvironment();
    await resetTestSettings();
    addTearDown(resetTestSettings);
    tester.view.physicalSize = const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      await createApplication(
        config,
        secureStore: InMemorySecureStore(),
        connectivityService: const StaticConnectivityService(),
      ),
    );

    // Bounded frames until home's first frame: the feed composes only after it.
    var homeSeen = false;
    for (var frame = 0; frame < 20; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('home-greeting')).evaluate().isNotEmpty) {
        homeSeen = true;
        break;
      }
    }
    expect(homeSeen, isTrue, reason: 'home should render within bounded frames');
    expect(find.byKey(const ValueKey('home-activity-skeleton')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity-list')), findsNothing);

    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-activity-skeleton')), findsNothing);
    expect(find.byKey(const ValueKey('home-activity-list')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-activity-foundation-ready')),
      findsOneWidget,
    );
  });

  testWidgets('home pull-to-refresh surfaces the notConnected toast and dismisses the indicator', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    await resetTestSettings();
    addTearDown(resetTestSettings);
    tester.view.physicalSize = const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      await createApplication(
        config,
        secureStore: InMemorySecureStore(),
        connectivityService: const StaticConnectivityService(),
      ),
    );
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-activity-list')), findsOneWidget);

    // Drag down from the top to arm the indicator (flings get swallowed).
    await tester.drag(
      find.byKey(const ValueKey('home-layout-compact')),
      const Offset(0, 450),
    );
    await pumpAppFrames(tester);

    // Backend-free refresh surfaces the honest notConnected toast via AppToast.
    final translations = tester.element(find.byKey(const ValueKey('home-greeting'))).t;
    expect(find.text(translations.common.notConnected), findsOneWidget);
    // The indicator dismissed once the refresh future completed.
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });
}
