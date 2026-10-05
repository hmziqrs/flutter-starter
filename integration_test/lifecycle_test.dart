import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';

import 'integration_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'createApplication publishes binding-driven paused -> inactive -> resumed transitions',
    (
      tester,
    ) async {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.development);

      await resetTestSettings();
      addTearDown(resetTestSettings);
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        await createApplication(
          config,
          secureStore: InMemorySecureStore(),
          connectivityService: const StaticConnectivityService(),
        ),
      );
      await pumpAppFrames(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      final observedKinds = <AppLifecycleKind>[];
      container.listen(appLifecyclePhaseProvider, (_, next) {
        observedKinds.add(next.kind);
      });

      expect(container.read(appLifecyclePhaseProvider).kind, AppLifecycleKind.resumed);

      // Dispatch and assert in the same event-loop turn: on the live engine the
      // OS may interleave its own lifecycle messages once frames are pumped, so
      // the phase is read synchronously right after each binding transition.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(container.read(appLifecyclePhaseProvider).kind, AppLifecycleKind.paused);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(container.read(appLifecyclePhaseProvider).kind, AppLifecycleKind.inactive);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(container.read(appLifecyclePhaseProvider).kind, AppLifecycleKind.resumed);

      await pumpAppFrames(tester);
      expect(
        observedKinds,
        containsAllInOrder([
          AppLifecycleKind.paused,
          AppLifecycleKind.inactive,
          AppLifecycleKind.resumed,
        ]),
      );
      // The resume edge refreshes the router; the shell must survive it intact.
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}
