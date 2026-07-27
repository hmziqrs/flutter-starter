import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Deterministic [VersionGateStore] for unit tests and the dev-gallery.
///
/// Returns the seeded [requirement] (defaults to [UpdateRequirementNone]) for
/// every [check]. The production no-backend default constructed in
/// `AppDependencies.production` uses the `none` default so the app runs green
/// with zero backend and never fakes a block (C2). Test fakes and dev-gallery
/// fixtures seed `soft` / `hard` to exercise the gating UI deterministically.
/// Test-only — never constructed in production paths.
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
