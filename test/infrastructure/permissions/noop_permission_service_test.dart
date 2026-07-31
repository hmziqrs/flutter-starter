import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/permissions/noop_permission_service.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';

void main() {
  group('NoopPermissionService', () {
    const service = NoopPermissionService();

    test('requestStatus never fakes a grant for any kind', () async {
      for (final permission in AppPermission.values) {
        final status = await service.requestStatus(permission);
        expect(status, isA<PermissionDenied>(), reason: '$permission must not be granted');
        expect(status.isGranted, isFalse);
        expect(status.isPermanentlyDenied, isFalse);
      }
    });

    test('checkStatus never fakes a grant for any kind', () async {
      for (final permission in AppPermission.values) {
        final status = await service.checkStatus(permission);
        expect(status, isA<PermissionDenied>(), reason: '$permission must not be granted');
        expect(status.isGranted, isFalse);
      }
    });

    test('openSystemSettings completes (no platform surface to open)', () async {
      await expectLater(service.openSystemSettings(), completes);
    });

    test('is a const-constructible honest default (no backend wiring)', () async {
      const a = NoopPermissionService();
      const b = NoopPermissionService();
      expect(
        await a.requestStatus(AppPermission.camera),
        await b.requestStatus(AppPermission.camera),
      );
    });
  });

  group('PermissionStatus sealed hierarchy', () {
    test('exposes exactly the four documented variants', () {
      expect(permissionStatusVariants, hasLength(4));
      expect(permissionStatusVariants.whereType<PermissionGranted>(), hasLength(1));
      expect(permissionStatusVariants.whereType<PermissionDenied>(), hasLength(1));
      expect(permissionStatusVariants.whereType<PermissionPermanentlyDenied>(), hasLength(1));
      expect(permissionStatusVariants.whereType<PermissionRestricted>(), hasLength(1));
    });

    test('isGranted / isPermanentlyDenied are true only on the right variant', () {
      expect(const PermissionGranted().isGranted, isTrue);
      expect(const PermissionDenied().isGranted, isFalse);
      expect(const PermissionPermanentlyDenied().isGranted, isFalse);
      expect(const PermissionRestricted().isGranted, isFalse);

      expect(const PermissionPermanentlyDenied().isPermanentlyDenied, isTrue);
      expect(const PermissionGranted().isPermanentlyDenied, isFalse);
      expect(const PermissionDenied().isPermanentlyDenied, isFalse);
      expect(const PermissionRestricted().isPermanentlyDenied, isFalse);
    });
  });

  group('permissionDebugLabel', () {
    test('is exhaustive and redacted over AppPermission', () {
      expect(permissionDebugLabel(AppPermission.camera), 'camera');
      expect(permissionDebugLabel(AppPermission.photos), 'photos');
      expect(permissionDebugLabel(AppPermission.location), 'location');
    });
  });
}
