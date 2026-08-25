import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/shared/state/operation_exception.dart';

abstract interface class FeatureFlagsSource {
  Future<FeatureFlags> load();

  Stream<FeatureFlags> changes();
}

final class FeatureFlagsException extends OperationException {
  const FeatureFlagsException({required super.operation});

  @override
  String toString() => 'FeatureFlagsException: $operation failed';
}

final featureFlagsSourceProvider = Provider<FeatureFlagsSource>(
  (ref) => throw StateError('FeatureFlagsSource must be overridden at the composition root.'),
);
