import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/splash/app_startup_result.dart';

/// Handwritten Riverpod handle forwarding the [AppStartupResult] future from
/// `createApplication`. Overridden at the composition root (AppDependencies +
/// ProviderScope in app.dart) with the existing init future; throws until
/// wired, mirroring `settingsStoreProvider` / `versionCheckProvider`.
///
/// SplashPage watches this and hands off to home/onboarding on resolve. It
/// never re-runs settings, locale, or package_info load — the future is the
/// single source of truth produced once in the composition root. No codegen.
final appStartupResultProvider = FutureProvider<AppStartupResult>(
  (ref) => throw StateError(
    'AppStartupResult must be overridden at the composition root.',
  ),
);
