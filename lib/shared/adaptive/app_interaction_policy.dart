/// The input-aware density and affordance policy used by the application UI.
///
/// Layout width is deliberately absent from this model. A compact desktop
/// window can retain precision-pointer behavior, while a large touch device can
/// retain touch behavior.
enum AppInteractionPolicy {
  touch,
  precisionPointer,
  hybrid,
}

/// The platform's conservative input default before runtime input is observed.
///
/// Platform detection belongs at the composition boundary. The resolver only
/// consumes this injectable value and never reads a platform API itself.
enum AppInteractionPlatformDefault {
  touchFirst,
  desktopFirst,
}

/// An input category observed during the current application session.
///
/// Callers should accumulate observations for the session rather than treating
/// pointer removal as a reason to downgrade the current interaction policy.
enum AppObservedInput {
  touch,
  precisionPointer,
}

/// Deterministically resolves an interaction policy from input-only signals.
final class AppInteractionPolicyResolver {
  const AppInteractionPolicyResolver({
    required this.platformDefault,
    this.override,
  });

  /// The safe policy baseline selected by the application composition root.
  final AppInteractionPlatformDefault platformDefault;

  /// An explicit policy used by tests, gallery previews, or app-level policy.
  ///
  /// An override takes precedence over both the platform default and observed
  /// inputs so every mode can be exercised deterministically.
  final AppInteractionPolicy? override;

  /// Resolves the effective policy for cumulative session [observedInputs].
  AppInteractionPolicy resolve({
    Set<AppObservedInput> observedInputs = const <AppObservedInput>{},
  }) {
    final explicitPolicy = override;
    if (explicitPolicy != null) return explicitPolicy;

    final observedTouch = observedInputs.contains(AppObservedInput.touch);
    final observedPrecisionPointer = observedInputs.contains(
      AppObservedInput.precisionPointer,
    );

    return switch (platformDefault) {
      AppInteractionPlatformDefault.touchFirst =>
        observedPrecisionPointer ? AppInteractionPolicy.hybrid : AppInteractionPolicy.touch,
      AppInteractionPlatformDefault.desktopFirst =>
        observedTouch ? AppInteractionPolicy.hybrid : AppInteractionPolicy.precisionPointer,
    };
  }
}
