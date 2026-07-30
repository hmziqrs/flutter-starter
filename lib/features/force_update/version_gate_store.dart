import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Compares the installed build against a published version policy and
/// reports the required update action. Implementations must degrade to
/// [UpdateRequirementNone] on failure: a policy that cannot be read must
/// never fabricate a hard or soft block.
abstract interface class VersionGateStore {
  /// Returns the [UpdateRequirement] derived from [buildInfo] and the published
  /// policy. Never throws for backend failures — returns
  /// [UpdateRequirementNone] instead.
  Future<UpdateRequirement> check(AppBuildInfo buildInfo);

  /// Store deep-link advertised by the last successful [check], or `null` when
  /// no policy has been read. Read-only description for diagnostics; behavior
  /// reads the value carried by the returned [UpdateRequirement].
  String? get storeUrl;
}

/// Thrown by [VersionGateStore] implementations only for programmer errors
/// (never for backend failures, which degrade to [UpdateRequirementNone]).
final class VersionGateException implements Exception {
  const VersionGateException({required this.operation});

  final String operation;

  @override
  String toString() => 'VersionGateException: $operation failed';
}
