import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/devtools/real_inspector_host.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

/// Development entrypoint (`flutter run --target=lib/main_dev.dart`, used by
/// `just run <device>`). Wires a [RealInspectorHost] so the dio_request_inspector
/// overlay works in development; it self-disables without dev tools/backend.
///
/// Kept unreachable from `lib/main.dart` so `package:dio_request_inspector` is
/// excluded from release AOT, avoiding the Flutter AOT snapshotter crash
/// (flutter/flutter#188060).
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
