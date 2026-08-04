import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AuthFeedbackAlertSpec {
  const AuthFeedbackAlertSpec({
    required this.title,
    this.variant = .primary,
    this.subtitle,
    this.icon,
    this.key,
  });

  final Key? key;

  final FAlertVariant variant;

  final Widget title;

  final Widget? subtitle;

  final Widget? icon;
}

class AuthFeedbackAlert<S> extends StatelessWidget {
  const AuthFeedbackAlert({required this.spec, super.key});

  static Widget? forStatus<S>({
    required S status,
    required AuthFeedbackAlertSpec? Function(S status) specFor,
  }) {
    final spec = specFor(status);
    if (spec == null) return null;
    return AuthFeedbackAlert<S>(spec: spec);
  }

  final AuthFeedbackAlertSpec spec;

  @override
  Widget build(BuildContext context) {
    return FAlert(
      key: spec.key,
      variant: spec.variant,
      title: spec.title,
      subtitle: spec.subtitle,
      icon: spec.icon,
    );
  }
}

class AuthAttemptsRemainingAlert extends StatelessWidget {
  const AuthAttemptsRemainingAlert({
    required this.remaining,
    required this.titleFor,
    super.key,
    this.alertKey,
  });

  static Widget? maybe({
    required int remaining,
    required bool locked,
    required Widget Function(int remaining) titleFor,
    Key? alertKey,
  }) {
    if (remaining <= 0 || locked) return null;
    return AuthAttemptsRemainingAlert(
      remaining: remaining,
      titleFor: titleFor,
      alertKey: alertKey,
    );
  }

  final int remaining;

  final Widget Function(int remaining) titleFor;

  final Key? alertKey;

  @override
  Widget build(BuildContext context) {
    return FAlert(key: alertKey, title: titleFor(remaining));
  }
}
