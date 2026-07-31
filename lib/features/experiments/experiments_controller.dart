import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

/// Immutable snapshot of every known experiment's current assignment. Built
/// by [ExperimentsController] from one [ExperimentSource.assignmentFor] call
/// per [ExperimentKey]; surfaced whole on the diagnostics page. Value
/// equality so the controller's diff commits only on a real change.
@immutable
final class ExperimentsSnapshot {
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

  /// Order-sensitive list equality (assignments are produced in
  /// [ExperimentKey] index order, so order is part of the snapshot's
  /// identity).
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

/// Publishes the resolved experiment snapshot as a handwritten `Notifier`.
///
/// `build` seeds [AsyncValue.loading] synchronously (an experiment read must
/// never block navigation), then resolves the full snapshot asynchronously
/// from [ExperimentSource.assignmentFor] for every known key. Live updates
/// flow through [ExperimentSource.changes]; poll-backed sources emit nothing
/// there and instead refresh on app resume (`inactive`/`hidden` never
/// trigger a refresh). A failing refresh keeps the current state rather than
/// surfacing an error or fabricating an assignment.
///
/// Consumers read the per-key variant through `experimentsProvider` (family)
/// or the whole snapshot through `experimentAssignmentsProvider`.
final experimentsControllerProvider =
    NotifierProvider<ExperimentsController, AsyncValue<ExperimentsSnapshot>>(
      ExperimentsController.new,
    );

final class ExperimentsController extends Notifier<AsyncValue<ExperimentsSnapshot>> {
  ExperimentSource get _source => ref.read(experimentSourceProvider);

  /// Monotonic counter bumped on every `changes()` event. A resume-driven
  /// refresh captures the counter before its await and commits only if no
  /// live change arrived while it was loading, so a stale refresh can never
  /// overwrite a fresher value.
  int _liveEpoch = 0;

  @override
  AsyncValue<ExperimentsSnapshot> build() {
    unawaited(_refresh());

    final subscription = _source.changes().listen((assignments) {
      _liveEpoch++;
      final next = ExperimentsSnapshot(assignments: assignments);
      final current = state.value;
      if (current != next) {
        state = AsyncValue<ExperimentsSnapshot>.data(next);
      }
    });

    // Re-load when the app returns to the foreground.
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
    }
  }

  /// The variant resolved for [key], or `null` while loading / before the key
  /// has an assignment.
  ExperimentVariant? variantFor(ExperimentKey key) => state.value?.variantFor(key);
}

/// Resolves a single experiment's variant reactively. Watches the snapshot
/// controller and maps the whole-snapshot state to the per-key variant:
/// `AsyncData` with an assignment maps to `AsyncData` with the variant;
/// `AsyncData` without one, or `AsyncLoading`, maps to `AsyncLoading`.
// The family builder returns a private Riverpod family type not part of
// flutter_riverpod's public API, so the top-level type is inferred.
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

/// The full assignment snapshot for the diagnostics page. Returns an empty
/// list while the controller is loading.
final experimentAssignmentsProvider = Provider<List<ExperimentAssignment>>((
  ref,
) {
  final snapshot = ref.watch(experimentsControllerProvider);
  return snapshot.value?.assignments ?? const <ExperimentAssignment>[];
});
