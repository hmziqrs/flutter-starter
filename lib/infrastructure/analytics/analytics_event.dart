import 'package:flutter/foundation.dart';

/// Typed analytics event. Sealed so every emit is exactly one of three known
/// shapes — no `Map<String, dynamic>` on the public surface.
@immutable
sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

/// A screen became visible. Emitted by `AnalyticsRouteObserver` on forward
/// navigation, replacement, and pop-to-screen — never by an individual page.
/// `routeName` is the resolved `go_router` route identifier
/// (`state.name ?? state.path`).
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

/// A tappable element was activated. `target` is a stable, product-defined
/// identifier for the control (not user-entered text).
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

/// A named funnel advanced to [step]. `name` identifies the funnel; `step` is
/// the zero-based ordinal of the stage reached.
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

/// A typed user property attached to the analytics identity. Values flow
/// through `AppLogger` so `LogRedactor` scrubs token/email formats before any
/// network sink sees them.
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
