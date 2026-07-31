import 'package:flutter/widgets.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';

enum AppViewingEnvironment {
  nearField,
  tenFoot,
}

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
