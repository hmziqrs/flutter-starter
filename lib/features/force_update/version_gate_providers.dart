import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Handwritten Riverpod handle for the [VersionGateStore] port.
///
/// Mirrors `settingsRepositoryProvider` / `secureStoreProvider`: it throws a
/// [StateError] until the composition root overrides it with a concrete adapter.
/// The no-backend default (`InMemoryVersionGateStore` returning `none`) is
/// constructed in `AppDependencies.production` and wired in `lib/app/app.dart`
/// as a peer of the other port overrides.
final versionGateStoreProvider = Provider<VersionGateStore>(
  (ref) => throw StateError('VersionGateStore must be overridden at the composition root.'),
);

/// Computes the [UpdateRequirement] exactly once per [ProviderContainer].
///
/// The default `create` runs the store check against a freshly loaded
/// [AppBuildInfo] — used by widget/integration tests that do not pre-warm. In
/// production, `createApplication` runs the check once (after `AppBuildInfo.load`,
/// never in a widget `build`) and overrides this provider with the resolved
/// value, so the redirect reads a ready [AsyncData] and the check never re-fires
/// on rebuild (C5: feed the redirect, do not compute in `build`).
final versionCheckProvider = FutureProvider<UpdateRequirement>((ref) async {
  final store = ref.watch(versionGateStoreProvider);
  return store.check(await AppBuildInfo.load());
});
