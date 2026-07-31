import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/splash/app_startup_result.dart';

final appStartupResultProvider = FutureProvider<AppStartupResult>(
  (ref) => throw StateError(
    'AppStartupResult must be overridden at the composition root.',
  ),
);
