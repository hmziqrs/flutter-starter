import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/shared/state/app_lifecycle_listener.dart';
import 'package:starter/shared/state/guarded_refresh_notifier.dart';

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

final class ExperimentsController extends Notifier<AsyncValue<ExperimentsSnapshot>>
    with GuardedRefreshNotifier<AsyncValue<ExperimentsSnapshot>> {
  ExperimentSource get _source => ref.read(experimentSourceProvider);

  @override
  AppLogger get logger => ref.read(appLoggerProvider);

  @override
  AsyncValue<ExperimentsSnapshot> build() {
    unawaited(_refresh());

    final subscription = _source.changes().listen((assignments) {
      bumpLiveEpoch();
      final next = ExperimentsSnapshot(assignments: assignments);
      final current = state.value;
      if (current != next) {
        state = AsyncValue<ExperimentsSnapshot>.data(next);
      }
    });

    ref.onDispose(subscription.cancel);
    listenOnResume(ref, _refresh);

    return const AsyncValue<ExperimentsSnapshot>.loading();
  }

  Future<void> _refresh() async {
    await guardedRefresh(
      load: () => Future.wait(
        <Future<ExperimentAssignment>>[
          for (final key in ExperimentKey.values) _source.assignmentFor(key),
        ],
      ),
      apply: (assignments) {
        final next = ExperimentsSnapshot(assignments: assignments);
        final current = state.value;
        if (current != next) {
          state = AsyncValue<ExperimentsSnapshot>.data(next);
        }
      },
      errorMessage: 'Experiment refresh failed',
    );
  }

  ExperimentVariant? variantFor(ExperimentKey key) => state.value?.variantFor(key);
}

// ignore: specify_nonobvious_property_types, inferred Riverpod family type
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
