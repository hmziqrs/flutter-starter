import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

/// Immutable snapshot of every known experiment's current assignment.
///
/// Built by [ExperimentsController] from one [ExperimentSource.assignmentFor]
/// call per [ExperimentKey]; surfaced whole on the diagnostics page under
/// `developmentToolsEnabled` (never assignment + deviceId together in
/// production logs — diagnostics is dev-only). Value equality so the
/// controller's diff commits only on a real change.
@immutable
final class ExperimentsSnapshot {
  /// Constructs a snapshot from the resolved [assignments].
  const ExperimentsSnapshot({this.assignments = const <ExperimentAssignment>[]});

  /// Every known experiment's current assignment, in [ExperimentKey] index
  /// order so the diagnostics read-out is stable.
  final List<ExperimentAssignment> assignments;

  /// The variant resolved for [key], or `null` if [key] has no assignment in
  /// this snapshot (e.g. while loading).
  ExperimentVariant? variantFor(ExperimentKey key) {
    for (final assignment in assignments) {
      if (assignment.key == key) {
        return assignment.variant;
      }
    }
    return null;
  }

  /// The full assignment for [key], or `null` if absent.
  ExperimentAssignment? assignmentFor(ExperimentKey key) {
    for (final assignment in assignments) {
      if (assignment.key == key) {
        return assignment;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExperimentsSnapshot && _listEquals(assignments, other.assignments);
  }

  @override
  int get hashCode => Object.hashAll(assignments);

  // Order-sensitive list equality (assignments are produced in ExperimentKey
  // index order, so order is part of the snapshot's identity).
  static bool _listEquals(
    List<ExperimentAssignment> a,
    List<ExperimentAssignment> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Publishes the resolved experiment snapshot as a handwritten `Notifier` (no
/// codegen), modeled on the peer `FeatureFlagsController`.
///
/// An experiment read on the UI thread must never block on a network call, and
/// navigation must never gate on an experiment (the spec's hard rule). `build`
/// seeds [AsyncValue.loading] synchronously so the first frame never awaits a
/// source, then resolves the full snapshot asynchronously from
/// [ExperimentSource.assignmentFor] for every known key. Live updates flow
/// through [ExperimentSource.changes] (the in-memory fake in tests; poll-backed
/// sources emit nothing and refresh through resume). Resume-refresh
/// (lifecycle-observer) re-loads on foreground so a device that received a new
/// assignment while backgrounded re-syncs immediately; `inactive`/`hidden` are
/// noisy and never trigger a refresh (mirrors `featureFlagsControllerProvider`
/// and `connectivityStatusProvider`).
///
/// A failing refresh degrades to the current state (loading or last known
/// snapshot) — a source that cannot be read must never surface an error to the
/// UI or fabricate a remote assignment (C2). Consumers read the per-key variant
/// through `experimentsProvider` (family) or the whole snapshot through
/// `experimentAssignmentsProvider` (diagnostics).
final experimentsControllerProvider =
    NotifierProvider<ExperimentsController, AsyncValue<ExperimentsSnapshot>>(
      ExperimentsController.new,
    );

final class ExperimentsController extends Notifier<AsyncValue<ExperimentsSnapshot>> {
  ExperimentSource get _source => ref.read(experimentSourceProvider);

  /// Monotonic counter bumped on every `changes()` event. A resume-driven
  /// refresh captures the counter before its await and commits only if no live
  /// change arrived while it was loading, so a stale refresh can never
  /// overwrite a fresher value delivered through `changes()`.
  int _liveEpoch = 0;

  @override
  AsyncValue<ExperimentsSnapshot> build() {
    // Seed loading synchronously: the UI never awaits a source on the first
    // frame, and experiments never gate navigation. The async refresh below
    // resolves the snapshot as soon as the source answers.
    unawaited(_refresh());

    // Live updates from sources that can push (the in-memory fake in tests).
    // Bumping `_liveEpoch` marks every push as the newest known state for the
    // load guard below.
    final subscription = _source.changes().listen((assignments) {
      _liveEpoch++;
      final next = ExperimentsSnapshot(assignments: assignments);
      final current = state.value;
      if (current != next) {
        state = AsyncValue<ExperimentsSnapshot>.data(next);
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

    return const AsyncValue<ExperimentsSnapshot>.loading();
  }

  Future<void> _refresh() async {
    // Capture the live epoch before the await; if a `changes()` event arrives
    // while we are loading, the guard below drops this (now stale) result.
    final epochAtStart = _liveEpoch;
    try {
      final assignments = await Future.wait(
        <Future<ExperimentAssignment>>[
          for (final key in ExperimentKey.values) _source.assignmentFor(key),
        ],
      );
      if (epochAtStart != _liveEpoch) {
        return;
      }
      final next = ExperimentsSnapshot(assignments: assignments);
      final current = state.value;
      if (current != next) {
        state = AsyncValue<ExperimentsSnapshot>.data(next);
      }
    } on Object {
      // Degrade: keep the current state (loading or the last known snapshot).
      // A source that cannot be read must never surface an error or fabricate
      // a remote assignment (C2).
    }
  }

  /// The variant resolved for [key], or `null` while loading / before the key
  /// has an assignment. Convenience accessor for callers that already hold the
  /// controller; the reactive per-key read is `experimentsProvider`.
  ExperimentVariant? variantFor(ExperimentKey key) => state.value?.variantFor(key);
}

/// Resolves a single experiment's variant reactively, as a family returning an
/// `AsyncValue<ExperimentVariant>` (per the feature contract). Watches the
/// snapshot controller and maps the whole-snapshot state to the per-key
/// variant:
/// - `AsyncData` with an assignment for the key -> `AsyncData` with the variant.
/// - `AsyncData` without an assignment for the key, or `AsyncLoading` ->
///   `AsyncLoading`.
/// - `AsyncError` -> `AsyncError` (the controller never sets this in practice;
///   it degrades, but the branch keeps the mapping total).
///
/// Because experiments never gate navigation, a consumer reading
/// `ref.watch(experimentsProvider(key))` renders its control-variant fallback
/// while loading and never blocks a route on the result.
// The family builder returns a private Riverpod family type that is not part of
// flutter_riverpod's public API, so the top-level type is inferred
// (non-obvious). Mirror the otp_controller family ignore.
// ignore: specify_nonobvious_property_types
final experimentsProvider = Provider.family<AsyncValue<ExperimentVariant>, ExperimentKey>((
  ref,
  key,
) {
  final snapshot = ref.watch(experimentsControllerProvider);
  return _resolveVariant(snapshot, key);
});

AsyncValue<ExperimentVariant> _resolveVariant(
  AsyncValue<ExperimentsSnapshot> snapshot,
  ExperimentKey key,
) {
  return switch (snapshot) {
    AsyncData(:final value) => _dataVariant(value, key),
    AsyncError(:final error, :final stackTrace) => AsyncValue<ExperimentVariant>.error(
      error,
      stackTrace,
    ),
    AsyncLoading() => const AsyncValue<ExperimentVariant>.loading(),
  };
}

AsyncValue<ExperimentVariant> _dataVariant(
  ExperimentsSnapshot value,
  ExperimentKey key,
) {
  final variant = value.variantFor(key);
  if (variant == null) {
    return const AsyncValue<ExperimentVariant>.loading();
  }
  return AsyncValue<ExperimentVariant>.data(variant);
}

/// The full assignment snapshot for the diagnostics page (dev-only). Returns
/// an empty list while the controller is loading so the diagnostics read-out
/// renders honestly (never fabricates an assignment).
final experimentAssignmentsProvider = Provider<List<ExperimentAssignment>>((
  ref,
) {
  final snapshot = ref.watch(experimentsControllerProvider);
  return snapshot.value?.assignments ?? const <ExperimentAssignment>[];
});
