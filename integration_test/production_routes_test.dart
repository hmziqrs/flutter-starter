import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/diagnostics/diagnostics_page.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/dev_gallery/screen_gallery_page.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';

import 'integration_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('production composition does not register development routes', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.production);
    expect(config.developmentToolsEnabled, isFalse);

    await resetTestSettings();
    addTearDown(resetTestSettings);

    for (final location in [
      AppRoutes.developmentScreensPath,
      AppRoutes.diagnosticsPath,
    ]) {
      await tester.pumpWidget(
        await createApplication(
          config,
          initialLocation: location,
          connectivityService: const StaticConnectivityService(),
        ),
      );
      await pumpAppFrames(tester);

      expect(find.byKey(const ValueKey('route-error-home')), findsOneWidget);
      expect(find.byType(ScreenGalleryPage), findsNothing);
      expect(find.byType(DiagnosticsPage), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAppFrames(tester);
    }
  });
}
