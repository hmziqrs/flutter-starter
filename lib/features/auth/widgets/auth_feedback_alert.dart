import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// Entry-flow feedback notices (BRAND.md section 9, Notice): one soft role
/// color as a thin line and an icon; title and body stay in the normal text
/// colors, the fill stays transparent.
class AuthFeedbackAlertSpec {
  const AuthFeedbackAlertSpec({
    required this.title,
    this.role = AppStatusRole.neutral,
    this.subtitle,
    this.icon,
    this.key,
  });

  final Key? key;

  final AppStatusRole role;

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

  /// The brand notice style for [role]: transparent fill, a thin role-colored
  /// line, the role color on the icon, and text in the normal colors. Type
  /// follows the shared notice recipe: body.sm w500 title, muted body.
  ///
  /// Exposed so entry screens that render a bare [FAlert] (countdowns,
  /// lockouts) read exactly like the spec-driven feedback notices.
  static FAlertStyleDelta noticeStyle(BuildContext context, AppStatusRole role) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final accent = context.theme.brand.roleColor(role) ?? colors.mutedForeground;
    return .delta(
      decoration: .value(
        ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: accent.withValues(alpha: 0.4)),
            borderRadius: context.theme.style.borderRadius.md,
          ),
        ),
      ),
      iconStyle: .delta(color: accent, size: 18),
      titleTextStyle: .delta(
        color: colors.foreground,
        fontSize: typography.body.sm.fontSize,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: .delta(
        color: colors.mutedForeground,
        fontSize: typography.body.sm.fontSize,
      ),
    );
  }

  /// The Lucide icon that carries [role] (BRAND.md section 6).
  static IconData roleIcon(AppStatusRole role) => switch (role) {
    AppStatusRole.destructive => FLucideIcons.octagonAlert,
    AppStatusRole.warning => FLucideIcons.triangleAlert,
    AppStatusRole.success => FLucideIcons.circleCheck,
    AppStatusRole.info || AppStatusRole.neutral => FLucideIcons.info,
  };

  final AuthFeedbackAlertSpec spec;

  @override
  Widget build(BuildContext context) {
    return FAlert(
      key: spec.key,
      style: noticeStyle(context, spec.role),
      icon: spec.icon ?? Icon(roleIcon(spec.role)),
      title: spec.title,
      subtitle: spec.subtitle,
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
    return FAlert(
      key: alertKey,
      style: AuthFeedbackAlert.noticeStyle(context, AppStatusRole.warning),
      icon: const Icon(FLucideIcons.triangleAlert),
      title: titleFor(remaining),
    );
  }
}
