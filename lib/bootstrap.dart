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
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/system_ui_controller.dart';

typedef ApplicationRunner = void Function(Widget application);

Future<void> bootstrap(
  AppConfig config, {
  AppLogger? logger,
  ApplicationRunner runApplication = runApp,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  // No-backend default. The optional SentryCrashReporter is constructed here
  // (and SentryFlutter.init run once) only once a crash-reporting DSN field
  // is added to AppConfig; until then the honest no-op sink is used (C2).
  // This runs before createApplication / the ProviderScope exists, so the
  // reporter is a direct parameter — never read via a provider here.
  const CrashReporter crashReporter = NoopCrashReporter();
  installErrorHandlers(appLogger, crashReporter);
  appLogger.info(
    'Starting application',
    context: <String, Object?>{'environment': config.environment.name},
  );

  runApplication(await createApplication(config, logger: appLogger));
}

/// Creates the same production dependency graph and root widget used by [bootstrap].
Future<App> createApplication(
  AppConfig config, {
  AppLogger? logger,
  String? initialLocation,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15 (API 35) enforces edge-to-edge; opt into transparent system
  // bars once after binding init so the first frame renders behind them
  // (system-ui feature). Idempotent; desktop/web short-circuit inside the
  // controller. Runs before AppBuildInfo.load / AppDependencies.production so
  // the posture is in place before any frame is constructed.
  await SystemUiController.applyEdgeToEdge(capabilities: PlatformCapabilities.current());

  final appLogger = logger ?? AppLogger(verbose: config.verboseLoggingEnabled);
  // Load AppBuildInfo ONCE and run the version check once in the composition
  // root (C5: never in a widget build). The result is carried on
  // AppDependencies.versionCheck and read by the redirect / force-update route.
  final buildInfo = await AppBuildInfo.load();
  final dependencies = await AppDependencies.production(
    appLogger,
    buildInfo: buildInfo,
    iosAppleId: config.iosAppleId,
    allowedDeepLinkHosts: config.allowedDeepLinkHosts,
  );
  // Apply the persisted locale once. Guarded so a failure flips
  // AppStartupResult.localeApplied to false (surfaced on the splash) rather
  // than tearing down startup; the device locale is the honest fallback.
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
  // Finalize the startup result now that the locale apply outcome is known.
  // AppDependencies.production sets localeApplied=true optimistically because
  // the apply runs after the factory returns; correct it here when it failed.
  final dependenciesWithStartup = localeApplied
      ? dependencies
      : dependencies.copyWith(
          appStartupResult: dependencies.appStartupResult.copyWith(localeApplied: localeApplied),
        );

  // Deep linking (deep-linking spec): capture the cold-start initial link
  // BEFORE the router builds so the deep link is not lost on first launch.
  // A plugin failure degrades honestly to "no initial link" so the app boots
  // to its normal initial location. The foreground link stream is wired in
  // `_AppViewState.ref.listen` (see lib/app/app.dart).
  String? coldStartInitialLocation;
  try {
    final initialLink = await dependencies.appLinkHandler.getInitialLink();
    if (initialLink != null) {
      coldStartInitialLocation = _initialLocationFromResolvedLink(initialLink);
    }
  } on Object {
    // A plugin failure must never strand startup. The app boots to its normal
    // initial location; foreground links still flow once the router mounts.
    coldStartInitialLocation = null;
  }

  // State-restoration: best-effort read of the saved last restorable route so
  // the user returns to where they left off. Precedence: explicit initialLocation
  // param (tests/integration) > cold-start deep link > saved last-route. The
  // saved route is intentionally WEAKER than the C5 redirect chain, which
  // re-evaluates AFTER initialLocation is set so update/onboarding/session/
  // biometric/passcode gates still win. A persistence failure degrades honestly
  // to "no saved route" (the splash/default initial location is the fallback).
  var effectiveInitialLocation = initialLocation ?? coldStartInitialLocation;
  if (effectiveInitialLocation == null) {
    try {
      final saved = await dependenciesWithStartup.settingsStore.readString(lastRouteKey);
      if (saved != null && saved.isNotEmpty) {
        effectiveInitialLocation = saved;
      }
    } on Object {
      // A persistence failure must never strand startup; boot to the default.
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

/// Wires the global error sinks so field failures reach triage.
///
/// Both [FlutterError.onError] (framework errors) and
/// `PlatformDispatcher.instance.onError` (uncaught async / platform errors) are
/// funneled to [AppLogger.error] for local dev visibility AND to [reporter]
/// (`recordFlutterError` / `recordError`) for remote ingest. Each capture is
/// fire-and-forget ([unawaited]) because the handler is synchronous and must
/// never block the framework error path; the platform handler returns `true` so
/// the error is treated as handled and never re-propagated.
///
/// Exposed for test access (annotated `@visibleForTesting`) so a regression that
/// drops the reporter call, drops the `return true` swallow, or re-awaits the
/// capture is caught by `test/bootstrap_test.dart` — the crash-reporting spec
/// requires this install site to be under test.
@visibleForTesting
void installErrorHandlers(AppLogger logger, CrashReporter reporter) {
  FlutterError.onError = (details) {
    logger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    // Fire-and-forget: the handler is synchronous and must never block the
    // framework error path. [unawaited] documents the intent.
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
