import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

abstract interface class VersionGateStore {
  Future<UpdateRequirement> check(AppBuildInfo buildInfo);

  String? get storeUrl;
}

final class VersionGateException implements Exception {
  const VersionGateException({required this.operation});

  final String operation;

  @override
  String toString() => 'VersionGateException: $operation failed';
}
