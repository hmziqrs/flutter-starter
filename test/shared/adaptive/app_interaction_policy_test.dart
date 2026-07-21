import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';

void main() {
  group('AppInteractionPolicyResolver', () {
    test('starts touch-first platforms in touch mode', () {
      const resolver = AppInteractionPolicyResolver(
        platformDefault: AppInteractionPlatformDefault.touchFirst,
      );

      expect(resolver.resolve(), AppInteractionPolicy.touch);
      expect(
        resolver.resolve(observedInputs: const <AppObservedInput>{AppObservedInput.touch}),
        AppInteractionPolicy.touch,
      );
    });

    test('starts desktop-first platforms in precision-pointer mode', () {
      const resolver = AppInteractionPolicyResolver(
        platformDefault: AppInteractionPlatformDefault.desktopFirst,
      );

      expect(resolver.resolve(), AppInteractionPolicy.precisionPointer);
      expect(
        resolver.resolve(
          observedInputs: const <AppObservedInput>{AppObservedInput.precisionPointer},
        ),
        AppInteractionPolicy.precisionPointer,
      );
    });

    test('promotes a touch-first session after precision input is observed', () {
      const resolver = AppInteractionPolicyResolver(
        platformDefault: AppInteractionPlatformDefault.touchFirst,
      );

      expect(
        resolver.resolve(
          observedInputs: const <AppObservedInput>{AppObservedInput.precisionPointer},
        ),
        AppInteractionPolicy.hybrid,
      );
    });

    test('promotes a desktop-first session after touch input is observed', () {
      const resolver = AppInteractionPolicyResolver(
        platformDefault: AppInteractionPlatformDefault.desktopFirst,
      );

      expect(
        resolver.resolve(observedInputs: const <AppObservedInput>{AppObservedInput.touch}),
        AppInteractionPolicy.hybrid,
      );
    });

    test('resolves both observed input categories to hybrid', () {
      const observedInputs = <AppObservedInput>{
        AppObservedInput.touch,
        AppObservedInput.precisionPointer,
      };
      const touchFirstResolver = AppInteractionPolicyResolver(
        platformDefault: AppInteractionPlatformDefault.touchFirst,
      );
      const desktopFirstResolver = AppInteractionPolicyResolver(
        platformDefault: AppInteractionPlatformDefault.desktopFirst,
      );

      expect(
        touchFirstResolver.resolve(observedInputs: observedInputs),
        AppInteractionPolicy.hybrid,
      );
      expect(
        desktopFirstResolver.resolve(observedInputs: observedInputs),
        AppInteractionPolicy.hybrid,
      );
    });

    test('explicit override takes precedence over every other signal', () {
      const observedInputs = <AppObservedInput>{
        AppObservedInput.touch,
        AppObservedInput.precisionPointer,
      };

      for (final policy in AppInteractionPolicy.values) {
        final resolver = AppInteractionPolicyResolver(
          platformDefault: AppInteractionPlatformDefault.desktopFirst,
          override: policy,
        );

        expect(resolver.resolve(observedInputs: observedInputs), policy);
      }
    });
  });
}
