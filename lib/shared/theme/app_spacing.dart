import 'package:flutter/widgets.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xl2 = 32.0;
  static const xl3 = 48.0;

  static const EdgeInsets screenPadding = EdgeInsets.all(xl);

  static AppSpacingValues of(BuildContext context) {
    return AppSpacingValues(
      context.appUnit,
      presentationScale: context.presentationTokens.spacingScale,
    );
  }
}

@immutable
final class AppSpacingValues {
  const AppSpacingValues(
    this._unit, {
    required this._presentationScale,
  });

  final AppUnit _unit;
  final double _presentationScale;

  double get xs => _scaled(AppSpacing.xs);
  double get sm => _scaled(AppSpacing.sm);
  double get md => _scaled(AppSpacing.md);
  double get lg => _scaled(AppSpacing.lg);
  double get xl => _scaled(AppSpacing.xl);
  double get xl2 => _scaled(AppSpacing.xl2);
  double get xl3 => _scaled(AppSpacing.xl3);

  double _scaled(double value) => _unit.un(value) * _presentationScale;
}

extension AppSpacingBuildContext on BuildContext {
  AppSpacingValues get spacing => AppSpacing.of(this);

  EdgeInsets get screenPadding => EdgeInsets.all(spacing.xl);
}
