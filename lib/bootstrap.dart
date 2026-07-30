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
  // Defaults to the no-op stub so the production entrypoint compiles no
  // dio_request_inspector code; lib/main_dev.dart overrides with the real host.
  InspectorHost inspectorHost = const StubInspectorHost(),
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  // FirebaseCrashlyticsCrashReporter self-disables on web/Linux/Windows and
  // when Firebase is not initialized, so the composite is safe with no backend.
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

/// Creates the same production dependency graph and root widget used by [bootstrap].
///
/// [secureStore] overrides the production OS-keychain-backed store; a headless
/// integration test injects an in-memory store to avoid the libsecret dependency.
Future<App> createApplication(
  AppConfig config, {
  AppLogger? logger,
  String? initialLocation,
  SecureStore? secureStore,
  InspectorHost inspectorHost = const StubInspectorHost(),
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15 enforces edge-to-edge; opt in before the first frame so it
  // doesn't render with an opaque system bar flash. Desktop/web no-op inside.
  await SystemUiController.applyEdgeToEdge(capabilities: PlatformCapabilities.current());

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  // Loaded once here (never inside a widget build) and carried on
  // AppDependencies.versionCheck for the redirect / force-update route.
  final buildInfo = await AppBuildInfo.load();
  final dependencies = await AppDependencies.production(
    appLogger,
    buildInfo: buildInfo,
    iosAppleId: config.iosAppleId,
    allowedDeepLinkHosts: config.allowedDeepLinkHosts,
    backendBaseUrl: config.backendBaseUrl,
    secureStore: secureStore,
    inspectorHost: inspectorHost,
  );
  // Guarded so a failure flips AppStartupResult.localeApplied to false
  // (surfaced on the splash) instead of tearing down startup.
  var localeApplied = true;
  if (dependencies.initialSettings.localeOverride case final locale?) {
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
  // AppDependencies.production sets localeApplied=true optimistically since the
  // apply runs after it returns; correct it here when the apply failed.
  final dependenciesWithStartup = localeApplied
      ? dependencies
      : dependencies.copyWith(
          appStartupResult: dependencies.appStartupResult.copyWith(localeApplied: localeApplied),
        );

  // Captured before the router builds so a cold-start deep link isn't lost.
  // The foreground link stream is wired in `_AppViewState.ref.listen`.
  String? coldStartInitialLocation;
  try {
    final initialLink = await dependencies.appLinkHandler.getInitialLink();
    if (initialLink != null) {
      coldStartInitialLocation = _initialLocationFromResolvedLink(initialLink);
    }
  } on Object {
    coldStartInitialLocation = null;
  }

  // Precedence: explicit initialLocation (tests/integration) > cold-start deep
  // link > saved last-route. Deliberately weaker than the redirect chain, which
  // re-evaluates after initialLocation is set so update/onboarding/session/
  // biometric/passcode gates still win.
  var effectiveInitialLocation = initialLocation ?? coldStartInitialLocation;
  if (effectiveInitialLocation == null) {
    try {
      final saved = await dependenciesWithStartup.settingsStore.readString(lastRouteKey);
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

/// Maps a cold-start [ResolvedLink] to the router's `initialLocation` string.
/// Reuses the [AppRoutes] helper for the OTP dynamic route; static routes use
/// their path constant directly. Used only at cold start — the foreground
/// stream dispatches via `context.goNamed` / `pushNamed` from `_AppViewState`.
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
  // An unknown resolved route falls back to home so a stale / future link
  // never strands the cold start.
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

/// Wires [FlutterError.onError] and `PlatformDispatcher.instance.onError` to
/// [AppLogger.error] and [reporter].
@visibleForTesting
void installErrorHandlers(AppLogger logger, CrashReporter reporter) {
  FlutterError.onError = (details) {
    logger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    // Fire-and-forget: the handler is synchronous and must never block the
    // framework error path.
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
    return true; // Marks the error handled so it isn't re-propagated.
  };
}
