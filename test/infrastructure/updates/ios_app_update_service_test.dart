import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/infrastructure/updates/ios_app_update_service.dart';

void main() {
  group('IosAppUpdateService', () {
    test('checkForUpdate honestly reports noUpdate (iOS forbids a programmatic check)', () async {
      final withId = IosAppUpdateService(appleId: '123456789');
      final empty = IosAppUpdateService(appleId: '');
      expect(await withId.checkForUpdate(), UpdateAvailability.noUpdate);
      expect(await empty.checkForUpdate(), UpdateAvailability.noUpdate);
    });

    test('launchUpdate is a silent no-op when the Apple ID is unset', () async {
      final service = IosAppUpdateService(appleId: '');
      await expectLater(service.launchUpdate(), completes);
      await expectLater(service.launchUpdate(immediate: true), completes);
    });

    test('launchUpdate degrades honestly when url_launcher has no platform binding', () async {
      final service = IosAppUpdateService(appleId: '123456789');
      await expectLater(service.launchUpdate(), completes);
    });
  });
}
