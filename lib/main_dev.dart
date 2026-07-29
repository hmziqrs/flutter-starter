import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/devtools/real_inspector_host.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

/// Development entrypoint.
///
/// Use with `flutter run --target=lib/main_dev.dart` (the `just run <device>`
/// recipe passes this target). Unlike the production entrypoint
/// (`lib/main.dart`), this wires a [RealInspectorHost] so the dio_request_inspector
/// overlay is fully functional in development. The host's own runtime gate
/// (development tools enabled AND a backend configured) keeps it inert for
/// no-backend / no-dev-tools launches, matching the prior behavior exactly.
///
/// This file is intentionally NOT reachable from `lib/main.dart`, so it — and
/// `package:dio_request_inspector` — is compiled only into development graphs
/// and is excluded from release AOT entirely (the production entrypoint's graph
/// imports only the no-op `StubInspectorHost`). That is what avoids the Flutter
/// AOT snapshotter crash (flutter/flutter#188060).
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
