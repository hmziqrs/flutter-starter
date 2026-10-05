import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/search/debounced_query_controller.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';

import 'integration_test_support.dart';

/// Search flow coverage promised by `search-pagination.md`: debounced
/// filtering on the real routed search page via `createApplication`, plus the
/// honest `notConnected` state-view on a Noop fetcher. Bounded frames only.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search debounces queries and the Noop paged list stays honest', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);
    expect(config.developmentToolsEnabled, isTrue);

    await resetTestSettings();
    addTearDown(resetTestSettings);
    tester.view.physicalSize = const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      await createApplication(
        config,
        initialLocation: AppRoutes.searchPath,
        secureStore: InMemorySecureStore(),
        connectivityService: const StaticConnectivityService(),
      ),
    );
    await pumpAppFrames(tester);

    for (var i = 0; i < 8; i += 1) {
      final dismiss = find.byKey(const ValueKey('announcement-dismiss'));
      if (dismiss.evaluate().isEmpty) break;
      await tester.tap(dismiss.hitTestable());
      await pumpAppFrames(tester);
    }

    expect(find.byKey(const ValueKey('search-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-result-search-result-auth')), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'biometric');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('search-result-search-result-auth')), findsOneWidget);

    await tester.pump(debounceQueryDuration);
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('search-result-search-result-biometric')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-result-search-result-auth')), findsNothing);

    // A matchless query renders the empty state-view.
    await tester.enterText(find.byType(EditableText), 'zzz-no-such-entry');
    await tester.pump(debounceQueryDuration);
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('empty-state-view')), findsOneWidget);
    expect(
      find.text(tester.element(find.byKey(const ValueKey('search-field'))).t.search.emptyTitle),
      findsOneWidget,
    );

    // Noop fetcher: the gallery's pagedNoBackend case surfaces notConnected.
    GoRouter.of(tester.element(find.byType(Navigator).first)).go(
      AppRoutes.developmentScreensPath,
    );
    await pumpAppFrames(tester);
    await tapVisible(tester, const ValueKey('gallery-screen-searchPagination'));
    await tapVisible(tester, const ValueKey('gallery-case-searchPagination.pagedNoBackend'));
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('error-state-view')), findsOneWidget);
    expect(
      find.text(
        tester.element(find.byKey(const ValueKey('gallery-controls-scroll'))).t.common.notConnected,
      ),
      findsOneWidget,
    );
  });
}
