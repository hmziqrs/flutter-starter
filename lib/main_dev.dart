import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/devtools/real_inspector_host.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

/// Separated from lib/main.dart to exclude dio_request_inspector from release AOT (flutter/flutter#188060).
Future<void> main() async {
  final fallbackLogger = AppLogger.bootstrap();
  final guardedMain = runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        final config = AppConfig.fromEnvironment();
        await bootstrap(
          config,
          inspectorHost: RealInspectorHost(
            developmentToolsEnabled: config.developmentToolsEnabled,
            backendBaseUrl: config.backendBaseUrl,
          ),
        );
      } on Object catch (error, stackTrace) {
        await showStartupFailure(
          error: error,
          stackTrace: stackTrace,
          logger: fallbackLogger,
        );
      }
    },
    (error, stackTrace) {
      fallbackLogger.error(
        'Unhandled zoned application error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );

  if (guardedMain != null) {
    await guardedMain;
  }
}
