import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The lifecycle phases the observer publishes, mirrored one-for-one from
/// [AppLifecycleState] so consuming features switch on a stable, app-owned
/// enum rather than the raw Flutter SDK type.
enum AppLifecycleKind { detached, resumed, inactive, hidden, paused }

/// A typed snapshot of the application lifecycle at a single instant.
///
/// Wraps the framework [AppLifecycleState] (as [kind]) together with the
/// [transitionedAt] instant the phase was reported. Consumers `ref.watch`
/// [appLifecyclePhaseProvider] and switch on [kind]; nobody mutates a phase
/// directly — only `didChangeAppLifecycleState` in `_AppViewState` pushes
/// transitions through [AppLifecycleController.transitionTo].
@immutable
final class AppLifecyclePhase {
  const AppLifecyclePhase({required this.kind, required this.transitionedAt});

  /// The phase assumed before the observer reports a real transition.
  ///
  /// The Dart isolate is running and building widgets, so the app is treated
  /// as foreground-resumed until the first [AppLifecycleState] callback
  /// arrives. This is load-bearing on desktop/web, where no transition is
  /// ever fired yet the app is plainly in the foreground.
  factory AppLifecyclePhase.initial() {
    return AppLifecyclePhase(
      kind: AppLifecycleKind.resumed,
      transitionedAt: DateTime.now(),
    );
  }

  final AppLifecycleKind kind;

  /// When this phase was reported. Captured at the framework transition, never
  /// mutated; consuming features read it for telemetry, never to gate work.
  final DateTime transitionedAt;

  /// True only on the foreground edge.
  ///
  /// Consuming features gate re-validation work (connectivity refresh, session
  /// token refresh, future auto-lock) on this — `inactive`/`hidden` are noisy
  /// (overlays, system sheets, notifications) and must not trigger refreshes.
  bool get isResumed => kind == AppLifecycleKind.resumed;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppLifecyclePhase && kind == other.kind && transitionedAt == other.transitionedAt;
  }

  @override
  int get hashCode => Object.hash(kind, transitionedAt);
}

/// Publishes the current [AppLifecyclePhase].
///
/// A handwritten `NotifierProvider` (no codegen), mirroring
/// `settingsControllerProvider` rather than the derived `interactionPolicyProvider`:
/// it owns mutable state that a real `Notifier` writes. The observer mixed into
/// `_AppViewState` is the only writer; every other feature reads.
///
/// Tests inject transitions by calling [AppLifecycleController.transitionTo] on
/// the notifier, or by overriding this provider at the App `ProviderScope` when
/// a fixed phase is required.
final appLifecyclePhaseProvider = NotifierProvider<AppLifecycleController, AppLifecyclePhase>(
  AppLifecycleController.new,
);

/// Owns the single source of truth for the app lifecycle phase.
///
/// This controller publishes state only. Resume-refresh, pause, and auto-lock
/// behavior belongs to the consuming features; do not grow this into a
/// dispatcher.
final class AppLifecycleController extends Notifier<AppLifecyclePhase> {
  @override
  AppLifecyclePhase build() => AppLifecyclePhase.initial();

  /// Records a framework lifecycle transition as the typed phase.
  ///
  /// Called only from `WidgetsBindingObserver.didChangeAppLifecycleState` in
  /// `_AppViewState`. The exhaustive switch over [AppLifecycleState] is the
  /// single mapping point from the framework enum to the app-owned
  /// [AppLifecycleKind].
  void transitionTo(AppLifecycleState frameworkState) {
    state = AppLifecyclePhase(
      kind: _kindFromState(frameworkState),
      transitionedAt: DateTime.now(),
    );
  }
}

AppLifecycleKind _kindFromState(AppLifecycleState state) {
  return switch (state) {
    AppLifecycleState.detached => AppLifecycleKind.detached,
    AppLifecycleState.resumed => AppLifecycleKind.resumed,
    AppLifecycleState.inactive => AppLifecycleKind.inactive,
    AppLifecycleState.hidden => AppLifecycleKind.hidden,
    AppLifecycleState.paused => AppLifecycleKind.paused,
  };
}
