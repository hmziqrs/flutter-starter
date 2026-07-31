import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

final versionGateStoreProvider = Provider<VersionGateStore>(
  (ref) => throw StateError('VersionGateStore must be overridden at the composition root.'),
);

final versionCheckProvider = FutureProvider<UpdateRequirement>((ref) async {
  final store = ref.watch(versionGateStoreProvider);
  return store.check(await AppBuildInfo.load());
});
