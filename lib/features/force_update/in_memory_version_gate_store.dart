import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

final class InMemoryVersionGateStore implements VersionGateStore {
  InMemoryVersionGateStore({
    this.requirement = const UpdateRequirementNone(),
    this.storeUrl,
  });

  final UpdateRequirement requirement;

  @override
  final String? storeUrl;

  @override
  Future<UpdateRequirement> check(AppBuildInfo buildInfo) async => requirement;
}
