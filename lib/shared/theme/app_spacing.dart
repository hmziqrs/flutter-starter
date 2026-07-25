import 'package:flutter/widgets.dart';
import 'package:starter/shared/adaptive/app_unit.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xl2 = 32.0;
  static const xl3 = 48.0;

  static AppSpacingValues of(BuildContext context) {
    return AppSpacingValues(context.appUnit);
  }
}

@immutable
final class AppSpacingValues {
  const AppSpacingValues(this._unit);

  final AppUnit _unit;

  double get xs => _unit.un(AppSpacing.xs);
  double get sm => _unit.un(AppSpacing.sm);
  double get md => _unit.un(AppSpacing.md);
  double get lg => _unit.un(AppSpacing.lg);
  double get xl => _unit.un(AppSpacing.xl);
  double get xl2 => _unit.un(AppSpacing.xl2);
  double get xl3 => _unit.un(AppSpacing.xl3);
}

extension AppSpacingBuildContext on BuildContext {
  AppSpacingValues get spacing => AppSpacing.of(this);
}
