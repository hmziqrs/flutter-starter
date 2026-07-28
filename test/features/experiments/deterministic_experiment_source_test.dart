import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/experiments/deterministic_experiment_source.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';

void main() {
  group('DeterministicExperimentSource', () {
    test('assignment is local, sticky, and never throws', () async {
      final store = InMemorySettingsStore();
      final source = DeterministicExperimentSource(store: store);
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.key, ExperimentKey.paywallLayout);
      expect(assignment.sticky, isTrue);
      expect(assignment.source, ExperimentAssignmentSource.local);
      expect(ExperimentVariantKind.values, contains(assignment.variant.kind));
    });

    test('persists the stable id and reuses it across instances', () async {
      // First instance generates + persists the id under the canonical key.
      final store = InMemorySettingsStore();
      final first = DeterministicExperimentSource(store: store);
      final firstAssignment = await first.assignmentFor(ExperimentKey.paywallLayout);

      // The id was persisted.
      final persisted = await store.readString(DeterministicExperimentSource.defaultStableIdKey);
      expect(persisted, isNotNull);
      expect(persisted!.length, 32); // 128-bit hex

      // A second source over the SAME store reads the same id and resolves the
      // same assignment (sticky-assignment contract: no re-bucket across
      // rebuilds).
      final second = DeterministicExperimentSource(store: store);
      final secondAssignment = await second.assignmentFor(ExperimentKey.paywallLayout);
      expect(secondAssignment, firstAssignment);
    });

    test('bucketing is a pure function of (stableId, key.wireKey)', () {
      final source = DeterministicExperimentSource(store: InMemorySettingsStore());
      const id = 'deadbeefdeadbeefdeadbeefdeadbeef';
      // Same inputs -> same arm, deterministically, across repeated calls.
      final a1 = source.bucket(ExperimentKey.paywallLayout, id);
      final a2 = source.bucket(ExperimentKey.paywallLayout, id);
      expect(a1, a2);
      // Different keys hash independently (the bucket input is scoped per
      // wireKey, so adding a new experiment never re-buckets an existing one).
      final paywall = source.bucket(ExperimentKey.paywallLayout, id);
      final onboarding = source.bucket(ExperimentKey.onboardingCta, id);
      // We do NOT assert the arms differ (they coincidentally could match); we
      // assert each is a valid variant resolved independently without cross-key
      // coupling.
      expect(paywall, isA<ExperimentVariant>());
      expect(onboarding, isA<ExperimentVariant>());
    });

    test('changing the salt re-buckets the space deliberately', () {
      final defaultSource = DeterministicExperimentSource(store: InMemorySettingsStore());
      final saltedSource = DeterministicExperimentSource(
        store: InMemorySettingsStore(),
        salt: 'alt-rollout.v2',
      );
      // Across a wide id set, the two salts must disagree on at least one id
      // for some key (else the salt is a no-op, which would defeat the
      // re-bucketing escape hatch).
      var disagreed = false;
      for (var i = 0; i < 200; i++) {
        final synthetic = i.toRadixString(16).padLeft(32, '0');
        final key = ExperimentKey.values[i % ExperimentKey.values.length];
        if (defaultSource.bucket(key, synthetic) != saltedSource.bucket(key, synthetic)) {
          disagreed = true;
          break;
        }
      }
      expect(disagreed, isTrue, reason: 'salt had no observable effect');
    });

    test('allocation percentages hold within a loose tolerance over many ids', () {
      // Statistical sanity, not a hard assertion (per the spec). Bucket a 50/50
      // experiment over 2000 synthetic ids and expect control within 40-60%.
      const key = ExperimentKey.paywallLayout;
      final source = DeterministicExperimentSource(store: InMemorySettingsStore());
      var control = 0;
      const total = 2000;
      for (var i = 0; i < total; i++) {
        final id = (i * 8191).toRadixString(16).padLeft(32, '0');
        if (source.bucket(key, id).kind == ExperimentVariantKind.control) {
          control++;
        }
      }
      final ratio = control / total;
      expect(ratio, greaterThanOrEqualTo(0.40));
      expect(ratio, lessThanOrEqualTo(0.60));
    });

    test('changes emits nothing (deterministic, never re-buckets)', () async {
      final source = DeterministicExperimentSource(store: InMemorySettingsStore());
      expect(await source.changes().isEmpty, isTrue);
    });

    test('a read failure degrades honestly to a generated in-memory id', () async {
      final store = InMemorySettingsStore()..failReads = true;
      final source = DeterministicExperimentSource(store: store);
      // Never throws; resolves a real local assignment despite the read failure.
      final assignment = await source.assignmentFor(ExperimentKey.homeFeedOrder);
      expect(assignment.source, ExperimentAssignmentSource.local);
      expect(assignment.sticky, isTrue);
    });

    test('a write failure still resolves an assignment for the session', () async {
      final store = InMemorySettingsStore()..failWrites = true;
      final source = DeterministicExperimentSource(store: store);
      final assignment = await source.assignmentFor(ExperimentKey.onboardingCta);
      expect(assignment.variant, isA<ExperimentVariant>());
    });

    test('an empty persisted id is regenerated', () async {
      final store = InMemorySettingsStore(
        seed: const {
          DeterministicExperimentSource.defaultStableIdKey: '',
        },
      );
      final source = DeterministicExperimentSource(store: store);
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      // The empty id was treated as missing and replaced.
      final after = await store.readString(DeterministicExperimentSource.defaultStableIdKey);
      expect(after, isNot(''));
      expect(after, isNotNull);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });

    test('a custom stableIdKey is honored', () async {
      const customKey = 'experiments.custom_id';
      final store = InMemorySettingsStore();
      final source = DeterministicExperimentSource(
        store: store,
        stableIdKey: customKey,
      );
      await source.assignmentFor(ExperimentKey.paywallLayout);
      final persistedDefault = await store.readString(
        DeterministicExperimentSource.defaultStableIdKey,
      );
      final persistedCustom = await store.readString(customKey);
      expect(persistedDefault, isNull);
      expect(persistedCustom, isNotNull);
    });
  });
}
