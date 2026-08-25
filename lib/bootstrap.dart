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

Future<void> bootstrap(
  AppConfig config, {
  AppLogger? logger,
  ApplicationRunner runApplication = runApp,
  InspectorHost inspectorHost = const StubInspectorHost(),
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  final CrashReporter crashReporter = CompositeCrashReporter(<CrashReporter>[
    const NoopCrashReporter(),
    FirebaseCrashlyticsCrashReporter(verbose: config.verboseLoggingEnabled),
  ]);
  installErrorHandlers(appLogger, crashReporter);
  appLogger.info(
    'Starting application',
    context: <String, Object?>{'environment': config.environment.name},
  );

  final app = await createApplication(config, logger: appLogger, inspectorHost: inspectorHost);
  runApplication(inspectorHost.wrap(app));
}

Future<App> createApplication(
  AppConfig config, {
  AppLogger? logger,
  String? initialLocation,
  SecureStore? secureStore,
  InspectorHost inspectorHost = const StubInspectorHost(),
  ConnectivityService? connectivityService,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemUiController.applyEdgeToEdge(capabilities: PlatformCapabilities.current());

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  final buildInfo = await AppBuildInfo.load();
  final dependencies = await AppDependencies.production(
    appLogger,
    buildInfo: buildInfo,
    iosAppleId: config.iosAppleId,
    allowedDeepLinkHosts: config.allowedDeepLinkHosts,
    backendBaseUrl: config.backendBaseUrl,
    secureStore: secureStore,
    inspectorHost: inspectorHost,
    connectivityService: connectivityService,
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

  String? coldStartInitialLocation;
  try {
    final initialLink = await dependencies.platform.appLinkHandler.getInitialLink();
    if (initialLink != null) {
      coldStartInitialLocation = _initialLocationFromResolvedLink(initialLink);
    }
  } on Object {
    coldStartInitialLocation = null;
  }

  var effectiveInitialLocation = initialLocation ?? coldStartInitialLocation;
  if (effectiveInitialLocation == null) {
    try {
      final saved = await dependenciesWithStartup.settings.settingsStore.readString(lastRouteKey);
      if (saved != null && saved.isNotEmpty) {
        effectiveInitialLocation = saved;
      }
    } on Object {
      effectiveInitialLocation = null;
    }
  }

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
void installErrorHandlers(AppLogger logger, CrashReporter reporter) {
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
