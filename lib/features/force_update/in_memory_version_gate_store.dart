import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Deterministic [VersionGateStore] for the no-backend production default,
/// unit tests, and the dev-gallery. Returns the seeded [requirement] (defaults
/// to [UpdateRequirementNone]) for every [check].
final class InMemoryVersionGateStore implements VersionGateStore {
  InMemoryVersionGateStore({
    this.requirement = const UpdateRequirementNone(),
    this.storeUrl,
  });

  /// The requirement this store reports for every [check].
  final UpdateRequirement requirement;

  @override
  final String? storeUrl;

  @override
  Future<UpdateRequirement> check(AppBuildInfo buildInfo) async => requirement;
}
