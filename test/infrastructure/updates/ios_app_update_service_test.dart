import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/infrastructure/updates/ios_app_update_service.dart';

void main() {
  group('IosAppUpdateService', () {
    test('checkForUpdate honestly reports noUpdate (iOS forbids a programmatic check)', () async {
      // iOS App Store policy provides no in-app availability check; the adapter
      // must never fabricate `available`. This holds regardless of appleId.
      const withId = IosAppUpdateService(appleId: '123456789');
      const empty = IosAppUpdateService(appleId: '');
      expect(await withId.checkForUpdate(), UpdateAvailability.noUpdate);
      expect(await empty.checkForUpdate(), UpdateAvailability.noUpdate);
    });

    test('launchUpdate is a silent no-op when the Apple ID is unset', () async {
      const service = IosAppUpdateService(appleId: '');
      // Must not throw and must not open a store URL (no id → degrade honestly).
      await expectLater(service.launchUpdate(), completes);
      await expectLater(service.launchUpdate(immediate: true), completes);
    });

    test('launchUpdate degrades honestly when url_launcher has no platform binding', () async {
      // In the test runner there is no platform channel for url_launcher, so the
      // call must be swallowed (the soft nudge stays dismissible — no faked
      // success state is returned to the caller).
      const service = IosAppUpdateService(appleId: '123456789');
      await expectLater(service.launchUpdate(), completes);
    });
  });
}
