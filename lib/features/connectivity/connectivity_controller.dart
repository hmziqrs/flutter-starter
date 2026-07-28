import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';

/// Handwritten Riverpod handle for the [ConnectivityService] port.
///
/// Mirrors `settingsRepositoryProvider`: it throws a [StateError] until the
/// composition root overrides it with the production `ConnectivityPlusService`
/// (constructed in `AppDependencies.production`). The override is wired in
/// `lib/app/app.dart` as a peer of `settingsRepositoryProvider`. No codegen.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => throw StateError(
    'ConnectivityService must be overridden at the composition root.',
  ),
);

/// Publishes the live connectivity state as an [AsyncValue], seeded with the
/// service's synchronous [ConnectivityService.current] (the first event on
/// [ConnectivityService.states]) so a cold read never resolves to "unknown".
///
/// Resume-refresh (lifecycle-observer): when the app returns to the foreground
/// ([AppLifecycleKind.resumed]), the service re-reads platform connectivity — a
/// device that changed networks while backgrounded re-syncs immediately and the
/// new state flows through this stream. `inactive`/`hidden` are noisy and never
/// trigger a refresh.
final connectivityStatusProvider = StreamProvider<ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
    final wasResumed = previous?.isResumed ?? false;
    if (next.isResumed && !wasResumed) {
      // Fire-and-forget: the refresh re-emits on [ConnectivityService.states]
      // if the state actually changed. [unawaited] documents the intent.
      unawaited(service.refresh());
    }
  });
  return service.states;
});
