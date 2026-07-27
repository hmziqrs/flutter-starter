import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_controller.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';

/// A test-only [FeatureFlagsSource] whose [load] returns a mutable "next" value
/// and whose [changes] never emits. It isolates the controller's load-based
/// refresh path (initial hydrate + resume-refresh) from the changes-stream path.
class _LoadOnlySource implements FeatureFlagsSource {
  _LoadOnlySource(this.next);

  /// The flags returned by the next [load]; mutable so a test can swap the
  /// served value to exercise the resume-refresh path.
  FeatureFlags next;

  @override
  Future<FeatureFlags> load() async => next;

  @override
  Stream<FeatureFlags> changes() => const Stream<FeatureFlags>.empty();
}

Future<void> _until(
  ProviderContainer container,
  bool Function(FeatureFlags) predicate, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate(container.read(featureFlagsControllerProvider))) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'controller state never satisfied predicate; '
        'last=${container.read(featureFlagsControllerProvider)}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('FeatureFlagsController', () {
    test('initial state is the no-backend defaults', () {
      final source = InMemoryFeatureFlagsSource();
      final container = ProviderContainer(
        overrides: [featureFlagsSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      expect(
        container.read(featureFlagsControllerProvider),
        const FeatureFlags.defaults(),
      );
    });

    test('emits values pushed on the source changes stream', () async {
      final source = InMemoryFeatureFlagsSource();
      final container = ProviderContainer(
        overrides: [featureFlagsSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      container.read(featureFlagsControllerProvider);

      final next = FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true});
      source.emit(next);

      await _until(container, (flags) => flags == next);
    });

    test('typed getters and isEnabled return typed values', () async {
      final source = InMemoryFeatureFlagsSource();
      final container = ProviderContainer(
        overrides: [featureFlagsSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      addTearDown(source.dispose);

      final controller = container.read(featureFlagsControllerProvider.notifier);
      final next = FeatureFlags.fromSlice(const <String, Object?>{
        'checkout_v2': true,
        'checkout_rollout_percent': 70,
      });
      source.emit(next);

      await _until(container, (flags) => flags.checkoutV2);

      final state = container.read(featureFlagsControllerProvider);
      expect(state.checkoutV2, isTrue);
      expect(state.checkoutRolloutPercent, 70);
      expect(controller.isEnabled(FeatureFlag.checkoutV2), isTrue);
      expect(controller.isEnabled(FeatureFlag.homeRedesign), isFalse);
    });

    test('initial refresh applies the latest value from load', () async {
      final source = _LoadOnlySource(
        FeatureFlags.fromSlice(const <String, Object?>{'profile_sync': true}),
      );
      final container = ProviderContainer(
        overrides: [featureFlagsSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      container.read(featureFlagsControllerProvider);

      await _until(container, (flags) => flags.profileSync);
    });

    test('resume-refresh re-loads after returning to the foreground', () async {
      final source = _LoadOnlySource(const FeatureFlags.defaults());
      final container = ProviderContainer(
        overrides: [featureFlagsSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      // Force the controller to build and the initial refresh to settle.
      container.read(featureFlagsControllerProvider);
      await _until(container, (flags) => flags == const FeatureFlags.defaults());

      // Background the app, swap the served flags, then resume.
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.paused);
      source.next = FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true});
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.resumed);

      await _until(container, (flags) => flags.checkoutV2);
    });

    test('a failing load degrades to the current state (never throws/fabricates)', () async {
      final source = _ThrowingSource();
      final container = ProviderContainer(
        overrides: [featureFlagsSourceProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);

      // Building and resuming must not throw; state stays at the baseline.
      container.read(featureFlagsControllerProvider);
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.paused);
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.resumed);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        container.read(featureFlagsControllerProvider),
        const FeatureFlags.defaults(),
      );
    });
  });
}

/// A test-only source whose [load] always throws, to verify the controller's
/// try/on Object degrade path never surfaces an error or fabricates a flag.
class _ThrowingSource implements FeatureFlagsSource {
  @override
  Future<FeatureFlags> load() async => throw const FeatureFlagsException(operation: 'load');

  @override
  Stream<FeatureFlags> changes() => const Stream<FeatureFlags>.empty();
}
