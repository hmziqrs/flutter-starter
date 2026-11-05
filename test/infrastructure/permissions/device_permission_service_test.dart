import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/permissions/device_permission_service.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('choosing a photo on Android needs no permission, on any Android version', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final service = DevicePermissionService();

    expect(await service.checkStatus(AppPermission.photos), isA<PermissionGranted>());
    expect(await service.requestStatus(AppPermission.photos), isA<PermissionGranted>());
  });

  test('other platforms still ask the system for photo access', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final service = DevicePermissionService();

    // The plugin has no channel under test, so asking the system lands on the
    // service's safe failure path. That it got there at all is the point.
    expect(await service.checkStatus(AppPermission.photos), isA<PermissionDenied>());
  });
}
