import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/infrastructure/updates/noop_app_update_service.dart';

void main() {
  group('NoopAppUpdateService', () {
    test('checkForUpdate honestly reports noUpdate (never fakes an available update)', () async {
      const service = NoopAppUpdateService();
      final availability = await service.checkForUpdate();
      expect(availability, UpdateAvailability.noUpdate);
    });

    test('launchUpdate completes without throwing or faking a success state', () async {
      const service = NoopAppUpdateService();
      // Both flags should be accepted for port parity and resolve cleanly.
      await expectLater(service.launchUpdate(), completes);
      await expectLater(service.launchUpdate(immediate: true), completes);
    });

    test('is a const-constructible honest default (no backend wiring)', () async {
      const a = NoopAppUpdateService();
      const b = NoopAppUpdateService();
      expect(await a.checkForUpdate(), await b.checkForUpdate());
    });
  });

  group('UpdateAvailability', () {
    test('exposes exactly the noUpdate / available / required variants', () {
      const values = UpdateAvailability.values;
      expect(values, hasLength(3));
      expect(
        values,
        containsAll(const <UpdateAvailability>[
          UpdateAvailability.noUpdate,
          UpdateAvailability.available,
          UpdateAvailability.required,
        ]),
      );
    });

    test('variants are pairwise distinct', () {
      expect(UpdateAvailability.noUpdate == UpdateAvailability.available, isFalse);
      expect(UpdateAvailability.noUpdate == UpdateAvailability.required, isFalse);
      expect(UpdateAvailability.available == UpdateAvailability.required, isFalse);
    });
  });

  group('AppUpdateServiceException', () {
    test('carries the failing operation and renders a stable message', () {
      const exception = AppUpdateServiceException(operation: 'checkForUpdate');
      expect(exception.operation, 'checkForUpdate');
      expect(exception.toString(), 'AppUpdateServiceException: checkForUpdate failed');
    });
  });

  group('appUpdateServiceProvider', () {
    test('throws until overridden at the composition root', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // riverpod wraps the inner StateError; assert on the surfaced message so
      // the test is stable across riverpod error-wrapper changes.
      expect(
        () => container.read(appUpdateServiceProvider),
        throwsA(
          (Object error) => error.toString().contains('AppUpdateService must be overridden'),
        ),
      );
    });
  });
}
