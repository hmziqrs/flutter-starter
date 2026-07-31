import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => throw StateError(
    'ConnectivityService must be overridden at the composition root.',
  ),
);

final connectivityStatusProvider = StreamProvider<ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
    final wasResumed = previous?.isResumed ?? false;
    if (next.isResumed && !wasResumed) {
      unawaited(service.refresh());
    }
  });
  return service.states;
});
