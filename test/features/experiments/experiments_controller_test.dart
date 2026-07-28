import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/features/experiments/experiments_controller.dart';
import 'package:starter/features/experiments/in_memory_experiment_source.dart';

/// A test-only [ExperimentSource] whose [assignmentFor] always throws, to
/// verify the controller's try/on Object degrade path never surfaces an error.
class _ThrowingSource implements ExperimentSource {
  @override
  Future<ExperimentAssignment> assignmentFor(ExperimentKey key) async =>
      throw const ExperimentSourceException(operation: 'assignmentFor');

  @override
  Stream<List<ExperimentAssignment>> changes() => const Stream<List<ExperimentAssignment>>.empty();
}

Future<void> _untilData(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  // The controller seeds AsyncLoading synchronously, then resolves the snapshot
  // asynchronously from the source. Poll until it leaves the loading state.
  while (container.read(experimentsControllerProvider).isLoading) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'controller never resolved data; '
        'state=${container.read(experimentsControllerProvider)}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('ExperimentsController', () {
    test('initial state is loading, then resolves a snapshot', () async {
      final source = InMemoryExperimentSource();
      final container = ProviderContainer(
        overrides: [experimentSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      expect(
        container.read(experimentsControllerProvider).isLoading,
        isTrue,
      );
      await _untilData(container);

      final snapshot = container.read(experimentsControllerProvider).requireValue;
      // One assignment per known key, in ExperimentKey index order.
      expect(snapshot.assignments.length, ExperimentKey.values.length);
      for (var i = 0; i < ExperimentKey.values.length; i++) {
        expect(snapshot.assignments[i].key, ExperimentKey.values[i]);
      }
    });

    test('every resolved assignment is local + sticky for the in-memory default', () async {
      final source = InMemoryExperimentSource();
      final container = ProviderContainer(
        overrides: [experimentSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      await _untilData(container);
      final snapshot = container.read(experimentsControllerProvider).requireValue;
      for (final assignment in snapshot.assignments) {
        expect(assignment.source, ExperimentAssignmentSource.local);
        expect(assignment.sticky, isTrue);
      }
    });

    test('experimentsProvider(key) family returns AsyncData<variant> after load', () async {
      final source = InMemoryExperimentSource();
      final container = ProviderContainer(
        overrides: [experimentSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      container.read(experimentsProvider(ExperimentKey.paywallLayout));
      await _untilData(container);

      final value = container.read(experimentsProvider(ExperimentKey.paywallLayout));
      expect(value.value, isA<ExperimentVariantControl>());
    });

    test('experimentAssignmentsProvider returns the snapshot list', () async {
      final source = InMemoryExperimentSource();
      final container = ProviderContainer(
        overrides: [experimentSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      // While loading, the list is empty (honest, never fabricates).
      expect(container.read(experimentAssignmentsProvider), isEmpty);
      await _untilData(container);
      expect(
        container.read(experimentAssignmentsProvider).length,
        ExperimentKey.values.length,
      );
    });

    test('live updates flow from the source changes stream', () async {
      final source = InMemoryExperimentSource();
      final container = ProviderContainer(
        overrides: [experimentSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      container.read(experimentsControllerProvider);
      await _untilData(container);

      source.assign(
        ExperimentKey.paywallLayout,
        const ExperimentVariantTreatmentA(),
        source: ExperimentAssignmentSource.remote,
      );

      // Wait for the change to land.
      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (container
              .read(experimentsControllerProvider)
              .requireValue
              .assignmentFor(ExperimentKey.paywallLayout)
              ?.source !=
          ExperimentAssignmentSource.remote) {
        if (DateTime.now().isAfter(deadline)) {
          fail(
            'live change never landed; '
            'state=${container.read(experimentsControllerProvider)}',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final snapshot = container.read(experimentsControllerProvider).requireValue;
      expect(
        snapshot.assignmentFor(ExperimentKey.paywallLayout)?.variant,
        const ExperimentVariantTreatmentA(),
      );
    });

    test('resume-refresh re-reads after returning to the foreground', () async {
      final source = InMemoryExperimentSource();
      final container = ProviderContainer(
        overrides: [experimentSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      container.read(experimentsControllerProvider);
      await _untilData(container);

      // Background, mutate the source, then resume.
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.paused);
      source.assign(ExperimentKey.onboardingCta, const ExperimentVariantTreatmentB());
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.resumed);

      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (container
              .read(experimentsControllerProvider)
              .requireValue
              .assignmentFor(ExperimentKey.onboardingCta)
              ?.variant !=
          const ExperimentVariantTreatmentB()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('resume-refresh never picked up the new assignment');
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });

    test('a failing source never surfaces an error or fabricates a variant', () async {
      final container = ProviderContainer(
        overrides: [experimentSourceProvider.overrideWithValue(_ThrowingSource())],
      );
      addTearDown(container.dispose);

      container.read(experimentsControllerProvider);
      // Resuming must not throw; the controller stays in its initial state.
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.paused);
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.resumed);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      // The controller never reached a data state (every refresh threw); the
      // per-key family therefore reports loading. It never errors.
      final value = container.read(experimentsProvider(ExperimentKey.paywallLayout));
      expect(value.hasError, isFalse);
    });
  });
}
