import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLifecycleKind { detached, resumed, inactive, hidden, paused }

@immutable
final class AppLifecyclePhase {
  const AppLifecyclePhase({required this.kind, required this.transitionedAt});

  /// Defaults to resumed: desktop/web never fire an [AppLifecycleState] transition.
  factory AppLifecyclePhase.initial() {
    return AppLifecyclePhase(
      kind: AppLifecycleKind.resumed,
      transitionedAt: DateTime.now(),
    );
  }

  final AppLifecycleKind kind;

  final DateTime transitionedAt;

  /// `inactive`/`hidden` are noisy (overlays, sheets, notifications) and must not refresh.
  bool get isResumed => kind == AppLifecycleKind.resumed;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppLifecyclePhase && kind == other.kind && transitionedAt == other.transitionedAt;
  }

  @override
  int get hashCode => Object.hash(kind, transitionedAt);
}

final appLifecyclePhaseProvider = NotifierProvider<AppLifecycleController, AppLifecyclePhase>(
  AppLifecycleController.new,
);

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
