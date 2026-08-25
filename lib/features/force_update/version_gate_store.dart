import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/shared/state/operation_exception.dart';

abstract interface class VersionGateStore {
  Future<UpdateRequirement> check(AppBuildInfo buildInfo);

  String? get storeUrl;
}

final class VersionGateException extends OperationException {
  const VersionGateException({required super.operation});

  @override
  String toString() => 'VersionGateException: $operation failed';
}
