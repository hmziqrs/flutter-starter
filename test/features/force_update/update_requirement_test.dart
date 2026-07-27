import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/features/force_update/update_requirement.dart';

void main() {
  group('UpdateRequirement equality', () {
    test('none is a singleton value type', () {
      expect(const UpdateRequirementNone(), const UpdateRequirementNone());
    });

    test('soft compares by payload', () {
      const a = UpdateRequirementSoft(
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        storeUrl: 'https://example.test/store',
      );
      const b = UpdateRequirementSoft(
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        storeUrl: 'https://example.test/store',
      );
      const other = UpdateRequirementSoft(
        minVersion: '1.0.0',
        latestVersion: '1.3.0',
        storeUrl: 'https://example.test/store',
      );
      expect(a, b);
      expect(a, isNot(other));
    });

    test('hard compares by payload including message', () {
      const a = UpdateRequirementHard(
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        storeUrl: 'https://example.test/store',
        message: 'security',
      );
      const b = UpdateRequirementHard(
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        storeUrl: 'https://example.test/store',
        message: 'security',
      );
      const noMessage = UpdateRequirementHard(
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        storeUrl: 'https://example.test/store',
      );
      expect(a, b);
      expect(a, isNot(noMessage));
    });

    test('soft and hard with identical payloads are distinct', () {
      const soft = UpdateRequirementSoft(
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        storeUrl: 'https://example.test/store',
      );
      const hard = UpdateRequirementHard(
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        storeUrl: 'https://example.test/store',
      );
      expect(soft, isNot(hard));
    });
  });

  group('ForceUpdateState.from', () {
    test('maps none to an empty store url', () {
      final state = ForceUpdateState.from(const UpdateRequirementNone());
      expect(state.storeUrl, isEmpty);
      expect(state.latestVersion, isEmpty);
      expect(state.message, isNull);
    });

    test('maps soft payload', () {
      final state = ForceUpdateState.from(
        const UpdateRequirementSoft(
          minVersion: '1.0.0',
          latestVersion: '1.2.0',
          storeUrl: 'https://example.test/store',
          message: 'refresh',
        ),
      );
      expect(state.latestVersion, '1.2.0');
      expect(state.storeUrl, 'https://example.test/store');
      expect(state.message, 'refresh');
    });

    test('maps hard payload', () {
      final state = ForceUpdateState.from(
        const UpdateRequirementHard(
          minVersion: '2.0.0',
          latestVersion: '2.1.0',
          storeUrl: 'https://example.test/store',
        ),
      );
      expect(state.latestVersion, '2.1.0');
      expect(state.storeUrl, 'https://example.test/store');
      expect(state.message, isNull);
    });

    test('exhaustive switch covers every subtype', () {
      // Drives each branch once; a new subtype would fail to compile here.
      for (final requirement in const <UpdateRequirement>[
        UpdateRequirementNone(),
        UpdateRequirementSoft(
          minVersion: '1.0.0',
          latestVersion: '1.1.0',
          storeUrl: 'u',
        ),
        UpdateRequirementHard(
          minVersion: '1.0.0',
          latestVersion: '1.1.0',
          storeUrl: 'u',
        ),
      ]) {
        expect(ForceUpdateState.from(requirement), isA<ForceUpdateState>());
      }
    });
  });
}
