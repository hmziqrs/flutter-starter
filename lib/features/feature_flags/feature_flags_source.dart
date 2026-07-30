import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';

/// Typed source of `FeatureFlags` — the feature-flags reader on the shared
/// remote-config family. Lives with its feature; only the optional
/// production adapter reading a remote-config backend lives under
/// `lib/infrastructure/remote_config/`.
///
/// Implementations wrap their backing source in `try/on Object` and degrade
/// to the cached value (or `FeatureFlags.defaults`) on any backend failure.
abstract interface class FeatureFlagsSource {
  /// Returns the most recently resolved `FeatureFlags`. Never throws for
  /// backend failures — returns the cached value or `FeatureFlags.defaults`.
  Future<FeatureFlags> load();

  /// Live updates to the flags, for sources that can push (e.g. the in-memory
  /// fake). Poll-backed sources emit nothing here and refresh through `load`
  /// on demand.
  Stream<FeatureFlags> changes();
}

/// Thrown by `FeatureFlagsSource` implementations only for programmer errors
/// (never for backend failures, which degrade to the cached/default flags).
final class FeatureFlagsException implements Exception {
  const FeatureFlagsException({required this.operation});

  final String operation;

  @override
  String toString() => 'FeatureFlagsException: $operation failed';
}

/// Handwritten Riverpod handle for the [FeatureFlagsSource] port; throws a
/// [StateError] until the composition root overrides it. The no-backend
/// default (`InMemoryFeatureFlagsSource` returning [FeatureFlags.defaults])
/// is constructed in `AppDependencies.production`.
final featureFlagsSourceProvider = Provider<FeatureFlagsSource>(
  (ref) => throw StateError('FeatureFlagsSource must be overridden at the composition root.'),
);
