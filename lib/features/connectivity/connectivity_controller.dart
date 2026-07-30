import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

/// Handwritten Riverpod handle for the [ConnectivityService] port; throws a
/// [StateError] until the composition root overrides it with the production
/// `ConnectivityPlusService`.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => throw StateError(
    'ConnectivityService must be overridden at the composition root.',
  ),
);

/// Publishes the live connectivity state as an [AsyncValue], seeded with the
/// service's synchronous [ConnectivityService.current] (the first event on
/// [ConnectivityService.states]) so a cold read never resolves to "unknown".
///
/// Re-reads platform connectivity when the app returns to the foreground, so
/// a device that changed networks while backgrounded re-syncs immediately;
/// `inactive`/`hidden` never trigger a refresh.
final connectivityStatusProvider = StreamProvider<ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
    final wasResumed = previous?.isResumed ?? false;
    if (next.isResumed && !wasResumed) {
      // Fire-and-forget: re-emits on ConnectivityService.states if changed.
      unawaited(service.refresh());
    }
  });
  return service.states;
});
