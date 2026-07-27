import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';

/// Typed source of `FeatureFlags` — the feature-flags reader on the shared
/// remote-config family (C4).
///
/// The port lives **with its feature** (`lib/features/feature_flags/`, mirroring
/// the `SettingsStore` exemplar); only the optional production adapter that reads a
/// remote-config backend lives under `lib/infrastructure/remote_config/`. It is
/// one of three peer typed ports — alongside `VersionGateStore`
/// (update-blocker) and the future `ExperimentSource` (ab-experiments) — that
/// each own their own `InMemory` default and read a distinct slice from the
/// single shared backend wrapper. No reader opens its own backend connection.
///
/// Implementations wrap their backing source in `try/on Object` and degrade to
/// the cached value (or `FeatureFlags.defaults`) on any backend failure: a flags
/// source that cannot be read must never fabricate an enabled flag.
abstract interface class FeatureFlagsSource {
  /// Returns the most recently resolved `FeatureFlags`. Never throws for backend
  /// failures — returns the cached value or `FeatureFlags.defaults` instead.
  Future<FeatureFlags> load();

  /// Live updates to the flags, for sources that can push (e.g. the in-memory
  /// fake). Poll-backed sources (the optional remote-config adapter) emit
  /// nothing here and refresh through `load` on demand.
  Stream<FeatureFlags> changes();
}

/// Thrown by `FeatureFlagsSource` implementations only for programmer errors
/// (never for backend failures, which degrade to the cached/default flags).
/// Mirrors the peer `VersionGateException`.
final class FeatureFlagsException implements Exception {
  const FeatureFlagsException({required this.operation});

  final String operation;

  @override
  String toString() => 'FeatureFlagsException: $operation failed';
}

/// Handwritten Riverpod handle for the [FeatureFlagsSource] port.
///
/// Mirrors `settingsStoreProvider` / `versionGateStoreProvider`: it throws a
/// [StateError] until the composition root overrides it with a concrete adapter.
/// The no-backend default (`InMemoryFeatureFlagsSource` returning
/// [FeatureFlags.defaults]) is constructed in `AppDependencies.production` and
/// wired in `lib/app/app.dart` as a peer of the other port overrides. No codegen.
final featureFlagsSourceProvider = Provider<FeatureFlagsSource>(
  (ref) => throw StateError('FeatureFlagsSource must be overridden at the composition root.'),
);
