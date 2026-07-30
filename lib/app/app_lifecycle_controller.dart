import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mirrors [AppLifecycleState] so consumers switch on an app-owned enum.
enum AppLifecycleKind { detached, resumed, inactive, hidden, paused }

/// A typed snapshot of the application lifecycle at a single instant.
@immutable
final class AppLifecyclePhase {
  const AppLifecyclePhase({required this.kind, required this.transitionedAt});

  /// Defaults to resumed: load-bearing on desktop/web, where no
  /// [AppLifecycleState] transition is ever fired but the app is foreground.
  factory AppLifecyclePhase.initial() {
    return AppLifecyclePhase(
      kind: AppLifecycleKind.resumed,
      transitionedAt: DateTime.now(),
    );
  }

  final AppLifecycleKind kind;

  final DateTime transitionedAt;

  /// True only on the foreground edge; `inactive`/`hidden` are noisy
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

/// Publishes the current [AppLifecyclePhase]. The `_AppViewState` observer is
/// the only writer; every other feature reads.
final appLifecyclePhaseProvider = NotifierProvider<AppLifecycleController, AppLifecyclePhase>(
  AppLifecycleController.new,
);

/// Owns the single source of truth for the app lifecycle phase. Publishes
/// state only — resume-refresh, pause, and auto-lock behavior belongs to the
/// consuming features.
final class AppLifecycleController extends Notifier<AppLifecyclePhase> {
  @override
  AppLifecyclePhase build() => AppLifecyclePhase.initial();

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
