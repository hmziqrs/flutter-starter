import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/force_update/in_memory_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

void main() {
  const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');

  test('default store reports none and never fakes a block', () async {
    final store = InMemoryVersionGateStore();
    expect(await store.check(buildInfo), const UpdateRequirementNone());
    expect(store.storeUrl, isNull);
  });

  test('seeds a hard block for the dev-gallery / tests', () async {
    const requirement = UpdateRequirementHard(
      minVersion: '2.0.0',
      latestVersion: '2.1.0',
      storeUrl: 'https://example.test/store',
    );
    final store = InMemoryVersionGateStore(
      requirement: requirement,
      storeUrl: 'https://example.test/store',
    );
    expect(await store.check(buildInfo), requirement);
    expect(store.storeUrl, 'https://example.test/store');
  });

  test('check ignores the build info and returns the seeded requirement', () async {
    final store = InMemoryVersionGateStore(
      requirement: const UpdateRequirementSoft(
        minVersion: '1.4.0',
        latestVersion: '1.5.0',
        storeUrl: 'u',
      ),
    );
    const other = AppBuildInfo(version: '0.9.9', buildNumber: '9');
    expect(
      await store.check(other),
      isA<UpdateRequirementSoft>(),
    );
  });

  test('a fresh instance reports the newly configured requirement', () async {
    const requirement = UpdateRequirementHard(
      minVersion: '3.0.0',
      latestVersion: '3.1.0',
      storeUrl: 'u',
    );
    final store = InMemoryVersionGateStore(requirement: requirement);
    expect(await store.check(buildInfo), requirement);
  });
}
