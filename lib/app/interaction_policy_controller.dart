import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';

final interactionPolicyOverrideProvider = Provider<AppInteractionPolicy?>((ref) => null);

final interactionPlatformDefaultProvider = Provider<AppInteractionPlatformDefault>((ref) {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => AppInteractionPlatformDefault.touchFirst,
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => AppInteractionPlatformDefault.desktopFirst,
  };
});

final observedInputsProvider = NotifierProvider<ObservedInputsController, Set<AppObservedInput>>(
  ObservedInputsController.new,
);

final interactionPolicyProvider = Provider<AppInteractionPolicy>((ref) {
  final resolver = AppInteractionPolicyResolver(
    platformDefault: ref.watch(interactionPlatformDefaultProvider),
    override: ref.watch(interactionPolicyOverrideProvider),
  );
  return resolver.resolve(observedInputs: ref.watch(observedInputsProvider));
});

final class ObservedInputsController extends Notifier<Set<AppObservedInput>> {
  @override
  Set<AppObservedInput> build() => const <AppObservedInput>{};

  void observe(PointerDeviceKind kind) {
    final input = switch (kind) {
      PointerDeviceKind.touch => AppObservedInput.touch,
      PointerDeviceKind.mouse ||
      PointerDeviceKind.trackpad ||
      PointerDeviceKind.stylus ||
      PointerDeviceKind.invertedStylus => AppObservedInput.precisionPointer,
      PointerDeviceKind.unknown => null,
    };
    if (input == null || state.contains(input)) {
      return;
    }
    state = {...state, input};
  }
}

class AppInputObserver extends ConsumerWidget {
  const AppInputObserver({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => ref.read(observedInputsProvider.notifier).observe(event.kind),
      child: child,
    );
  }
}
