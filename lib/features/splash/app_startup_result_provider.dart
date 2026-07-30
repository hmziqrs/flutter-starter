import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/splash/app_startup_result.dart';

/// Riverpod handle forwarding the [AppStartupResult] future from
/// `createApplication`. Overridden at the composition root with the existing
/// init future; throws until wired. SplashPage watches this and hands off to
/// home/onboarding on resolve, never re-running the init work.
final appStartupResultProvider = FutureProvider<AppStartupResult>(
  (ref) => throw StateError(
    'AppStartupResult must be overridden at the composition root.',
  ),
);
