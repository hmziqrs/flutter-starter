import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

part 'experiments_controller.freezed.dart';

@freezed
abstract class ExperimentsSnapshot with _$ExperimentsSnapshot {
  const factory ExperimentsSnapshot({
    @Default(<ExperimentAssignment>[]) List<ExperimentAssignment> assignments,
  }) = _ExperimentsSnapshot;

  const ExperimentsSnapshot._();

  ExperimentVariant? variantFor(ExperimentKey key) {
    for (final assignment in assignments) {
      if (assignment.key == key) {
        return assignment.variant;
      }
    }
    return null;
  }

  ExperimentAssignment? assignmentFor(ExperimentKey key) {
    for (final assignment in assignments) {
      if (assignment.key == key) {
        return assignment;
      }
    }
    return null;
  }
}

final experimentsControllerProvider =
    NotifierProvider<ExperimentsController, AsyncValue<ExperimentsSnapshot>>(
      ExperimentsController.new,
    );

final class ExperimentsController extends Notifier<AsyncValue<ExperimentsSnapshot>> {
  ExperimentSource get _source => ref.read(experimentSourceProvider);

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

  ExperimentVariant? variantFor(ExperimentKey key) => state.value?.variantFor(key);
}

// Family builder returns a private Riverpod family type; the top-level type is inferred.
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

final experimentAssignmentsProvider = Provider<List<ExperimentAssignment>>((
  ref,
) {
  final snapshot = ref.watch(experimentsControllerProvider);
  return snapshot.value?.assignments ?? const <ExperimentAssignment>[];
});
