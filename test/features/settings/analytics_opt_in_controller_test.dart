import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/settings/analytics_opt_in_controller.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

void main() {
  group('AnalyticsOptInController', () {
    test('defaults to off while nothing is persisted', () {
      final store = InMemorySecureStore();
      final container = _buildContainer(store);
      addTearDown(container.dispose);

      expect(container.read(analyticsOptInControllerProvider), isFalse);
      expect(store.snapshot.containsKey(analyticsOptInKey), isFalse);
    });

    test('setOptIn(true) persists the analytics.opt_in SecureStore key', () async {
      final store = InMemorySecureStore();
      final container = _buildContainer(store);
      addTearDown(container.dispose);

      await container.read(analyticsOptInControllerProvider.notifier).setOptIn(value: true);

      expect(container.read(analyticsOptInControllerProvider), isTrue);
      expect(await store.read(analyticsOptInKey), 'true');
    });

    test('setOptIn(false) removes the key entirely', () async {
      final store = InMemorySecureStore(seed: {analyticsOptInKey: 'true'});
      final container = _buildContainer(store, initialOptIn: true);
      addTearDown(container.dispose);

      await container.read(analyticsOptInControllerProvider.notifier).setOptIn(value: false);

      expect(container.read(analyticsOptInControllerProvider), isFalse);
      expect(store.snapshot.containsKey(analyticsOptInKey), isFalse);
    });

    test('a failing write throws SecureStoreException and rolls the state back', () async {
      final store = InMemorySecureStore(seed: {analyticsOptInKey: 'true'})..failWrites = true;
      final container = _buildContainer(store, initialOptIn: true);
      addTearDown(container.dispose);
      final controller = container.read(analyticsOptInControllerProvider.notifier);

      await expectLater(
        controller.setOptIn(value: false),
        throwsA(isA<SecureStoreException>()),
      );

      expect(container.read(analyticsOptInControllerProvider), isTrue);
      expect(store.snapshot[analyticsOptInKey], 'true');
    });
  });
}

ProviderContainer _buildContainer(
  InMemorySecureStore store, {
  bool initialOptIn = false,
}) {
  return ProviderContainer(
    overrides: [
      secureStoreProvider.overrideWithValue(store),
      initialAnalyticsOptInProvider.overrideWithValue(initialOptIn),
    ],
  );
}
