import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app_lifecycle_controller.dart';

void main() {
  group('AppLifecyclePhase', () {
    test('initial phase is foreground-resumed', () {
      final phase = AppLifecyclePhase.initial();

      expect(phase.kind, AppLifecycleKind.resumed);
      expect(phase.isResumed, isTrue);
    });

    test('value equality covers kind and transitionedAt', () {
      final instant = DateTime.utc(2026, 7, 27, 12, 30);
      final a = AppLifecyclePhase(
        kind: AppLifecycleKind.paused,
        transitionedAt: instant,
      );
      final b = AppLifecyclePhase(
        kind: AppLifecycleKind.paused,
        transitionedAt: instant,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);

      final other = AppLifecyclePhase(
        kind: AppLifecycleKind.resumed,
        transitionedAt: instant,
      );
      expect(a == other, isFalse);
    });
  });

  group('AppLifecycleController', () {
    final scenarios = <({AppLifecycleState state, AppLifecycleKind kind})>[
      (
        state: AppLifecycleState.detached,
        kind: AppLifecycleKind.detached,
      ),
      (
        state: AppLifecycleState.resumed,
        kind: AppLifecycleKind.resumed,
      ),
      (
        state: AppLifecycleState.inactive,
        kind: AppLifecycleKind.inactive,
      ),
      (
        state: AppLifecycleState.hidden,
        kind: AppLifecycleKind.hidden,
      ),
      (
        state: AppLifecycleState.paused,
        kind: AppLifecycleKind.paused,
      ),
    ];

    test('build returns the resumed initial phase', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(appLifecyclePhaseProvider).kind,
        AppLifecycleKind.resumed,
      );
    });

    for (final scenario in scenarios) {
      test('transitionTo maps ${scenario.state} to ${scenario.kind}', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(appLifecyclePhaseProvider.notifier).transitionTo(scenario.state);

        expect(
          container.read(appLifecyclePhaseProvider).kind,
          scenario.kind,
        );
      });
    }

    test('transitionTo stamps the transition instant', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final start = DateTime.now();

      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.paused);

      final phase = container.read(appLifecyclePhaseProvider);
      expect(phase.kind, AppLifecycleKind.paused);
      expect(
        phase.transitionedAt.isAfter(start) || phase.transitionedAt.isAtSameMomentAs(start),
        isTrue,
      );
    });

    test('provider is overridable so consuming-feature tests can drive a phase', () {
      final container = ProviderContainer(
        overrides: [
          appLifecyclePhaseProvider.overrideWith(AppLifecycleController.new),
        ],
      );
      addTearDown(container.dispose);

      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.inactive);

      expect(
        container.read(appLifecyclePhaseProvider).kind,
        AppLifecycleKind.inactive,
      );
    });
  });
}
