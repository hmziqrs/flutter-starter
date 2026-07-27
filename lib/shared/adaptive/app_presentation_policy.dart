import 'package:flutter/widgets.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';

/// The distance-oriented viewing environment used by presentation policy.
///
/// Layout width is deliberately absent. A narrow deterministic preview can
/// exercise ten-foot behavior without changing its structural layout class.
enum AppViewingEnvironment {
  nearField,
  tenFoot,
}

/// The stable viewing and input policy shared by application presentation.
@immutable
final class AppPresentationPolicy {
  const AppPresentationPolicy({
    required this.viewingEnvironment,
    required this.interactionPolicy,
  });

  final AppViewingEnvironment viewingEnvironment;
  final AppInteractionPolicy interactionPolicy;

  bool get isTenFoot => viewingEnvironment == AppViewingEnvironment.tenFoot;

  bool get usesDirectionalFocus =>
      interactionPolicy == AppInteractionPolicy.remote ||
      interactionPolicy == AppInteractionPolicy.hybridRemote;

  /// Returns the presentation policy exposed by the nearest scope.
  static AppPresentationPolicy of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppPresentationScope>();
    if (scope == null) {
      throw FlutterError(
        'AppPresentationPolicy.of() called with a context that does not '
        'contain an AppPresentationScope.',
      );
    }
    return scope.policy;
  }

  static AppPresentationPolicy? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppPresentationScope>()?.policy;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppPresentationPolicy &&
            viewingEnvironment == other.viewingEnvironment &&
            interactionPolicy == other.interactionPolicy;
  }

  @override
  int get hashCode => Object.hash(viewingEnvironment, interactionPolicy);
}

/// Exposes one immutable presentation policy to layout and theme consumers.
class AppPresentationScope extends InheritedWidget {
  const AppPresentationScope({
    required this.policy,
    required super.child,
    super.key,
  });

  final AppPresentationPolicy policy;

  @override
  bool updateShouldNotify(AppPresentationScope oldWidget) {
    return policy != oldWidget.policy;
  }
}
