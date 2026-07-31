import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';

import '../../infrastructure/connectivity/fake_connectivity_service.dart';

void main() {
  group('connectivityServiceProvider', () {
    test('throws until overridden at the composition root', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(connectivityServiceProvider),
        throwsA(
          (Object error) => error.toString().contains('ConnectivityService must be overridden'),
        ),
      );
    });
  });

  group('connectivityStatusProvider', () {
    test('is seeded with the service current state', () async {
      final service = FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [connectivityServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      addTearDown(service.dispose);

      container.listen(connectivityStatusProvider, (_, _) {});
      await container.pump();

      expect(
        container.read(connectivityStatusProvider).value,
        ConnectivityState.online,
      );
    });

    test('forwards transitions emitted by the service', () async {
      final service = FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [connectivityServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      addTearDown(service.dispose);

      container.listen(connectivityStatusProvider, (_, _) {});
      await container.pump();

      service.emit(ConnectivityState.offline);
      await container.pump();
      expect(
        container.read(connectivityStatusProvider).value,
        ConnectivityState.offline,
      );

      service.emit(ConnectivityState.limited);
      await container.pump();
      expect(
        container.read(connectivityStatusProvider).value,
        ConnectivityState.limited,
      );

      service.emit(ConnectivityState.online);
      await container.pump();
      expect(
        container.read(connectivityStatusProvider).value,
        ConnectivityState.online,
      );
    });

    test('resume-refresh re-arms only on the resumed lifecycle edge', () async {
      final service = FakeConnectivityService();
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(service),
          appLifecyclePhaseProvider.overrideWith(AppLifecycleController.new),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(service.dispose);

      container.listen(connectivityStatusProvider, (_, _) {});
      await container.pump();

      final notifier = container.read(appLifecyclePhaseProvider.notifier);

      Future<void> transitionAndExpect(
        AppLifecycleState state,
        int expectedRefreshCount,
      ) async {
        notifier.transitionTo(state);
        await container.pump();
        expect(service.refreshCount, expectedRefreshCount);
      }

      await transitionAndExpect(AppLifecycleState.inactive, 0);
      await transitionAndExpect(AppLifecycleState.paused, 0);

      await transitionAndExpect(AppLifecycleState.resumed, 1);

      await transitionAndExpect(AppLifecycleState.resumed, 1);
    });
  });
}
