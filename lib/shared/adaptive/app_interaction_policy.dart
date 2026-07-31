enum AppInteractionPolicy {
  touch,
  precisionPointer,
  hybrid,
  remote,
  hybridRemote,
}

enum AppInteractionPlatformDefault {
  touchFirst,
  desktopFirst,
  remoteFirst,
}

enum AppObservedInput {
  touch,
  precisionPointer,
}

final class AppInteractionPolicyResolver {
  const AppInteractionPolicyResolver({
    required this.platformDefault,
    this.override,
  });

  final AppInteractionPlatformDefault platformDefault;

  final AppInteractionPolicy? override;

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
      AppInteractionPlatformDefault.remoteFirst =>
        observedPrecisionPointer ? AppInteractionPolicy.hybridRemote : AppInteractionPolicy.remote,
    };
  }
}
