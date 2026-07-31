import 'package:flutter/foundation.dart';

@immutable
sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

final class ScreenView extends AnalyticsEvent {
  const ScreenView({required this.routeName});

  final String routeName;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ScreenView && routeName == other.routeName;
  }

  @override
  int get hashCode => routeName.hashCode;
}

final class Tap extends AnalyticsEvent {
  const Tap({required this.target});

  final String target;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Tap && target == other.target;
  }

  @override
  int get hashCode => target.hashCode;
}

final class FunnelStep extends AnalyticsEvent {
  const FunnelStep({required this.name, required this.step});

  final String name;
  final int step;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FunnelStep && name == other.name && step == other.step;
  }

  @override
  int get hashCode => Object.hash(name, step);
}

@immutable
final class UserProperty {
  const UserProperty({required this.key, required this.value});

  final String key;
  final String value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProperty && key == other.key && value == other.value;
  }

  @override
  int get hashCode => Object.hash(key, value);
}
