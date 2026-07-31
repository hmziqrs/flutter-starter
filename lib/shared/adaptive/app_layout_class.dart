enum AppLayoutClass {
  compact,
  medium,
  expanded;

  static AppLayoutClass fromWidth(
    double width, {
    required double compactMax,
    required double expandedMin,
  }) {
    _validateThresholds(
      compactMax: compactMax,
      expandedMin: expandedMin,
    );

    if (!width.isFinite || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'Width must be finite and non-negative.',
      );
    }

    if (width < compactMax) return compact;
    if (width < expandedMin) return medium;
    return expanded;
  }

  static void _validateThresholds({
    required double compactMax,
    required double expandedMin,
  }) {
    if (!compactMax.isFinite || compactMax <= 0) {
      throw ArgumentError.value(
        compactMax,
        'compactMax',
        'The compact threshold must be finite and greater than zero.',
      );
    }

    if (!expandedMin.isFinite || expandedMin <= compactMax) {
      throw ArgumentError.value(
        expandedMin,
        'expandedMin',
        'The expanded threshold must be finite and greater than compactMax.',
      );
    }
  }
}
