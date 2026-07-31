import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/features/experiments/in_memory_experiment_source.dart';

void main() {
  group('InMemoryExperimentSource', () {
    test('an unseeded key resolves to a local control variant', () async {
      final source = InMemoryExperimentSource();
      addTearDown(source.dispose);
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.key, ExperimentKey.paywallLayout);
      expect(assignment.variant, const ExperimentVariantControl());
      expect(assignment.sticky, isTrue);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });

    test('a seeded initial assignment is returned as-is', () async {
      final source = InMemoryExperimentSource(
        initial: {
          ExperimentKey.paywallLayout: const ExperimentAssignment(
            key: ExperimentKey.paywallLayout,
            variant: ExperimentVariantTreatmentA(),
            sticky: true,
            source: ExperimentAssignmentSource.remote,
          ),
        },
      );
      addTearDown(source.dispose);
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.variant, const ExperimentVariantTreatmentA());
      expect(assignment.source, ExperimentAssignmentSource.remote);
    });

    test('assign updates the snapshot and emits on changes', () async {
      final source = InMemoryExperimentSource();
      addTearDown(source.dispose);
      final emitted = <List<ExperimentAssignment>>[];
      final subscription = source.changes().listen(emitted.add);
      addTearDown(subscription.cancel);

      source.assign(ExperimentKey.onboardingCta, const ExperimentVariantTreatmentB());

      final assignment = await source.assignmentFor(ExperimentKey.onboardingCta);
      expect(assignment.variant, const ExperimentVariantTreatmentB());

      expect(emitted, isNotEmpty);
      final last = emitted.last;
      final matched = last.where((a) => a.key == ExperimentKey.onboardingCta).single;
      expect(matched.variant, const ExperimentVariantTreatmentB());
    });

    test('snapshot reflects only the assigned keys', () {
      final source = InMemoryExperimentSource();
      addTearDown(source.dispose);
      expect(source.snapshot, isEmpty);
      source.assign(ExperimentKey.homeFeedOrder, const ExperimentVariantTreatmentC());
      expect(source.snapshot, hasLength(1));
      expect(source.snapshot.single.key, ExperimentKey.homeFeedOrder);
    });

    test('changes emits nothing before any assign', () async {
      final source = InMemoryExperimentSource();
      addTearDown(source.dispose);
      var events = 0;
      final subscription = source.changes().listen((_) => events++);
      addTearDown(subscription.cancel);
      // `.isEmpty` hangs on an open broadcast stream; assert no event in a timed window.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events, 0);
    });
  });
}
