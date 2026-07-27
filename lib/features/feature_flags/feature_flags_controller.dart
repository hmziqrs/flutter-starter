import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';

/// Publishes the resolved `FeatureFlags` as a handwritten `Notifier` (no
/// codegen), modeled on the peer `SettingsController`.
///
/// A flag read on the UI thread must never block on a network call: `build`
/// hydrates `FeatureFlags.defaults` **synchronously** so the first frame always
/// has a value, then refreshes asynchronously from `FeatureFlagsSource.load`.
/// Live updates flow through `FeatureFlagsSource.changes`. Resume-refresh
/// (lifecycle-observer) re-loads on foreground so a device that received a new
/// rollout while backgrounded re-syncs immediately; `inactive`/`hidden` are
/// noisy and never trigger a refresh (mirrors `connectivityStatusProvider`).
final featureFlagsControllerProvider = NotifierProvider<FeatureFlagsController, FeatureFlags>(
  FeatureFlagsController.new,
);

final class FeatureFlagsController extends Notifier<FeatureFlags> {
  FeatureFlagsSource get _source => ref.read(featureFlagsSourceProvider);

  /// Monotonic counter bumped on every `changes()` event. A load-based refresh
  /// captures the counter before its await and commits only if no live change
  /// arrived while it was loading, so a stale initial/resume load can never
  /// overwrite a fresher value delivered through `changes()`.
  int _liveEpoch = 0;

  @override
  FeatureFlags build() {
    // Hydrate synchronously: the UI reads a ready value on the first frame and
    // never awaits a backend. The async refresh below emits if the source
    // resolves something other than the baseline and no live change preempts it.
    unawaited(_refresh());

    // Live updates from sources that can push (the in-memory fake in tests; a
    // future push-backed real impl). Poll-backed adapters emit nothing here and
    // refresh through `_refresh` on resume instead. Bumping `_liveEpoch` here
    // marks every push as the newest known state for the load guard above.
    final subscription = _source.changes().listen((flags) {
      _liveEpoch++;
      if (state != flags) {
        state = flags;
      }
    });

    // Resume-refresh: re-load when the app returns to the foreground.
    ref
      ..onDispose(subscription.cancel)
      ..listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
        final wasResumed = previous?.isResumed ?? false;
        if (next.isResumed && !wasResumed) {
          unawaited(_refresh());
        }
      });

    return const FeatureFlags.defaults();
  }

  Future<void> _refresh() async {
    // Capture the live epoch before the await; if a `changes()` event arrives
    // while we are loading, the guard below drops this (now stale) result.
    final epochAtStart = _liveEpoch;
    try {
      final flags = await _source.load();
      if (epochAtStart == _liveEpoch && state != flags) {
        state = flags;
      }
    } on Object {
      // Degrade: keep the current state (already the baseline or the last
      // known value). A flags source that cannot be read must never fabricate
      // an enabled flag (C2).
    }
  }

  /// Typed, dynamic lookup delegating to the current `FeatureFlags.isEnabled`.
  bool isEnabled(FeatureFlag flag) => state.isEnabled(flag);
}
