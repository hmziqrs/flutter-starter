import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

final presentationPolicyOverrideProvider = Provider<AppPresentationPolicy?>((ref) => null);

final presentationPolicyProvider = Provider<AppPresentationPolicy>((ref) {
  final override = ref.watch(presentationPolicyOverrideProvider);
  if (override != null) {
    return override;
  }

  final capabilities = ref.watch(platformCapabilitiesProvider);
  return AppPresentationPolicy(
    viewingEnvironment: capabilities.isTelevision
        ? AppViewingEnvironment.tenFoot
        : AppViewingEnvironment.nearField,
    interactionPolicy: ref.watch(interactionPolicyProvider),
  );
});
