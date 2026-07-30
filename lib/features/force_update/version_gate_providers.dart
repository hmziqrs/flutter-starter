import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Riverpod handle for the [VersionGateStore] port. Throws a [StateError]
/// until the composition root overrides it with a concrete adapter.
final versionGateStoreProvider = Provider<VersionGateStore>(
  (ref) => throw StateError('VersionGateStore must be overridden at the composition root.'),
);

/// Computes the [UpdateRequirement] exactly once per [ProviderContainer]. In
/// production this is overridden with an already-resolved value so the
/// redirect reads a ready [AsyncData] and the check never re-fires on rebuild.
final versionCheckProvider = FutureProvider<UpdateRequirement>((ref) async {
  final store = ref.watch(versionGateStoreProvider);
  return store.check(await AppBuildInfo.load());
});
