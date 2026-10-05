import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/startup/startup_error_view.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';
import 'package:starter/infrastructure/devtools/stub_inspector_host.dart';
import 'package:starter/infrastructure/error_reporting/composite_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/firebase_crashlytics_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/system_ui_controller.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

typedef ApplicationRunner = void Function(Widget application);

/// Zone-visible crash sink: [installErrorHandlers] swaps in each reporter as
/// the boot pair is replaced by the production composite, so errors caught by
/// [bootstrapApplication]'s zone guard reach the same composite as framework
/// and platform errors instead of dying in a log-only handler.
@visibleForTesting
final class ZonedCrashSink {
  CrashReporter reporter = const NoopCrashReporter();

  Future<void> report(Object error, StackTrace stackTrace) {
    return reporter.recordError(
      error,
      stackTrace,
      context: <String, Object?>{'source': 'zone'},
    );
  }
}

/// Zone-guarded process entrypoint: loads the compile-time config, boots the
/// app, and renders the startup-failure UI when loading or booting throws.
///
/// [inspectorHost] receives the loaded config because dev-tool hosts are
/// derived from config values.
Future<void> bootstrapApplication({
  InspectorHost Function(AppConfig config)? inspectorHost,
  ApplicationRunner runApplication = runApp,
}) async {
  final fallbackLogger = AppLogger.bootstrap();
  final zonedCrashSink = ZonedCrashSink();
  final guardedMain = runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        final config = AppConfig.fromEnvironment();
        await bootstrap(
          config,
          runApplication: runApplication,
          inspectorHost: inspectorHost?.call(config) ?? const StubInspectorHost(),
          zonedCrashSink: zonedCrashSink,
        );
      } on Object catch (error, stackTrace) {
        await showStartupFailure(
          error: error,
          stackTrace: stackTrace,
          logger: fallbackLogger,
          runApplication: runApplication,
        );
      }
    },
    (error, stackTrace) {
      fallbackLogger.error(
        'Unhandled zoned application error',
        error: error,
        stackTrace: stackTrace,
      );
      unawaited(zonedCrashSink.report(error, stackTrace));
    },
  );

  if (guardedMain != null) {
    await guardedMain;
  }
}

Future<void> bootstrap(
  AppConfig config, {
  AppLogger? logger,
  ApplicationRunner runApplication = runApp,
  InspectorHost inspectorHost = const StubInspectorHost(),
  ZonedCrashSink? zonedCrashSink,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  // Boot window: the production composite (which carries the HTTP reporter
  // when `backendBaseUrl` is set) only exists once `AppDependencies.production`
  // resolves, so errors raised while it loads route to the always-safe pair.
  installErrorHandlers(appLogger, _bootCrashReporter(config), zonedCrashSink: zonedCrashSink);
  appLogger.info(
    'Starting application',
    context: <String, Object?>{'environment': config.environment.name},
  );

  final app = await createApplication(config, logger: appLogger, inspectorHost: inspectorHost);
  // Re-arm the handlers with the production composite — with `backendBaseUrl`
  // set this includes the HTTP reporter, so a wired backend needs no
  // hand-wiring at the install site.
  installErrorHandlers(
    appLogger,
    app.dependencies.telemetry.crashReporter,
    zonedCrashSink: zonedCrashSink,
  );
  runApplication(inspectorHost.wrap(app));
}

CrashReporter _bootCrashReporter(AppConfig config) {
  return CompositeCrashReporter(<CrashReporter>[
    const NoopCrashReporter(),
    FirebaseCrashlyticsCrashReporter(verbose: config.verboseLoggingEnabled),
  ]);
}

Future<App> createApplication(
  AppConfig config, {
  AppLogger? logger,
  String? initialLocation,
  SecureStore? secureStore,
  InspectorHost inspectorHost = const StubInspectorHost(),
  ConnectivityService? connectivityService,
  DeepLinkService? appLinkHandler,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final edgeToEdgeFuture = SystemUiController.applyEdgeToEdge(
    capabilities: PlatformCapabilities.current(),
  )..ignore();
  final buildInfoFuture = AppBuildInfo.load()..ignore();

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  final dependencies = await AppDependencies.production(
    appLogger,
    buildInfo: buildInfoFuture,
    iosAppleId: config.iosAppleId,
    allowedDeepLinkHosts: config.allowedDeepLinkHosts,
    backendBaseUrl: config.backendBaseUrl,
    verboseLoggingEnabled: config.verboseLoggingEnabled,
    secureStore: secureStore,
    inspectorHost: inspectorHost,
    connectivityService: connectivityService,
    appLinkHandler: appLinkHandler,
  );
  var localeApplied = true;
  if (dependencies.settings.initialSettings.localeOverride case final locale?) {
    try {
      await LocaleSettings.setLocale(locale);
    } on Object {
      localeApplied = false;
    }
  } else {
    try {
      await LocaleSettings.useDeviceLocale();
    } on Object {
      localeApplied = false;
    }
  }
  final dependenciesWithStartup = localeApplied
      ? dependencies
      : dependencies.copyWith(
          appStartupResult: dependencies.appStartupResult.copyWith(localeApplied: localeApplied),
        );

  var effectiveInitialLocation = initialLocation;
  if (effectiveInitialLocation == null) {
    final initialLinkFuture = dependencies.platform.appLinkHandler.getInitialLink();
    final savedRouteFuture = dependenciesWithStartup.settings.settingsStore.readString(
      lastRouteKey,
    );
    String? coldStartInitialLocation;
    try {
      final initialLink = await initialLinkFuture;
      if (initialLink != null) {
        coldStartInitialLocation = _initialLocationFromResolvedLink(initialLink);
      }
    } on Object {
      coldStartInitialLocation = null;
    }
    String? savedRoute;
    try {
      savedRoute = await savedRouteFuture;
    } on Object {
      savedRoute = null;
    }
    if (coldStartInitialLocation != null) {
      effectiveInitialLocation = coldStartInitialLocation;
    } else if (savedRoute != null && savedRoute.isNotEmpty) {
      effectiveInitialLocation = savedRoute;
    }
  }

  await edgeToEdgeFuture;

  return App(
    config: config,
    dependencies: dependenciesWithStartup,
    initialLocation: effectiveInitialLocation,
  );
}

String _initialLocationFromResolvedLink(ResolvedLink link) {
  switch (link.routeName) {
    case AppRoutes.home:
      return AppRoutes.homePath;
    case AppRoutes.login:
      return AppRoutes.loginPath;
    case AppRoutes.register:
      return AppRoutes.registerPath;
    case AppRoutes.forgotPassword:
      return AppRoutes.forgotPasswordPath;
    case AppRoutes.resetPassword:
      return AppRoutes.resetPasswordPath;
    case AppRoutes.settings:
      return AppRoutes.settingsPath;
    case AppRoutes.pricing:
      return AppRoutes.pricingPath;
    case AppRoutes.otp:
      final purpose = link.pathParameters['purpose'];
      if (purpose == null) {
        return AppRoutes.homePath;
      }
      return '/auth/otp/$purpose';
  }
  return AppRoutes.homePath;
}

Future<void> showStartupFailure({
  required Object error,
  required StackTrace stackTrace,
  AppLogger? logger,
  ApplicationRunner runApplication = runApp,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  (logger ?? AppLogger.bootstrap()).error(
    'Application startup failed',
    error: error,
    stackTrace: stackTrace,
  );

  try {
    await LocaleSettings.useDeviceLocale();
  } on Object {
    await LocaleSettings.setLocale(AppLocale.en);
  }

  runApplication(
    StartupErrorApp(
      diagnosticId: startupDiagnosticIdFor(error),
    ),
  );
}

@visibleForTesting
void installErrorHandlers(
  AppLogger logger,
  CrashReporter reporter, {
  ZonedCrashSink? zonedCrashSink,
}) {
  zonedCrashSink?.reporter = reporter;
  FlutterError.onError = (details) {
    logger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    unawaited(reporter.recordFlutterError(details));
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error(
      'Uncaught platform error',
      error: error,
      stackTrace: stackTrace,
    );
    unawaited(
      reporter.recordError(
        error,
        stackTrace,
        context: <String, Object?>{'source': 'platform'},
      ),
    );
    return true;
  };
}
