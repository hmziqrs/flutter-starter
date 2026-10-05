import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';

import 'support/pump_app_frames.dart';

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

  group('_AppView binding wiring', () {
    final developmentConfig = AppConfig(
      environment: AppEnvironment.development,
      enableVerboseLogging: true,
      enableDevTools: true,
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    );

    testWidgets('mount registers the observer; binding transitions reach the provider', (
      tester,
    ) async {
      await tester.pumpWidget(
        App(config: developmentConfig, dependencies: AppDependencies.inMemory()),
      );
      await pumpAppFrames(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      final observedKinds = <AppLifecycleKind>[];
      container.listen(appLifecyclePhaseProvider, (_, next) {
        observedKinds.add(next.kind);
      });

      expect(container.read(appLifecyclePhaseProvider).kind, AppLifecycleKind.resumed);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await pumpAppFrames(tester);
      expect(container.read(appLifecyclePhaseProvider).kind, AppLifecycleKind.paused);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpAppFrames(tester);
      expect(container.read(appLifecyclePhaseProvider).kind, AppLifecycleKind.resumed);
      expect(observedKinds, [AppLifecycleKind.paused, AppLifecycleKind.resumed]);
    });

    testWidgets('dispose unregisters the observer; no phase is emitted afterwards', (
      tester,
    ) async {
      await tester.pumpWidget(
        App(config: developmentConfig, dependencies: AppDependencies.inMemory()),
      );
      await pumpAppFrames(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      final observedKinds = <AppLifecycleKind>[];
      container.listen(appLifecyclePhaseProvider, (_, next) {
        observedKinds.add(next.kind);
      });

      // Tear the app down the way the runner would, disposing _AppView.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAppFrames(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await pumpAppFrames(tester);

      // The observer was removed on dispose: no transition, no framework error.
      expect(observedKinds, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
