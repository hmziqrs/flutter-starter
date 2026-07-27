import 'package:flutter/services.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';

/// Production `HapticService` backed by the cross-platform `HapticFeedback`
/// surface from `flutter/services`.
///
/// The exhaustive `switch` over [HapticKind] is the single source of truth for
/// the kind -> `HapticFeedback` mapping; adding a kind is a compile error here
/// until a branch handles it (strict-analysis guardrail). A platform-call
/// failure (missing channel binding, unsupported platform) is wrapped in
/// `HapticServiceException` for port-discipline; call sites treat haptics as
/// fire-and-forget and swallow it, so a failed buzz never gates a user action.
///
/// Constructed in `AppDependencies.production` (the local device IS the backend
/// — no credentials, no faking) and overridden at the `ProviderScope` as a peer
/// of the other port overrides. Tests/goldens override with `NoopHapticService`
/// instead so no real haptic fires during capture.
final class DeviceHapticService implements HapticService {
  const DeviceHapticService();

  @override
  Future<void> trigger(HapticKind kind) async {
    try {
      switch (kind) {
        case HapticKind.selection:
          await HapticFeedback.selectionClick();
        case HapticKind.impactLight:
          await HapticFeedback.lightImpact();
        case HapticKind.impactMedium:
          await HapticFeedback.mediumImpact();
        case HapticKind.impactHeavy:
          await HapticFeedback.heavyImpact();
        case HapticKind.notificationSuccess:
          await HapticFeedback.successNotification();
        case HapticKind.notificationWarning:
          await HapticFeedback.warningNotification();
        case HapticKind.notificationError:
          await HapticFeedback.errorNotification();
      }
    } on HapticServiceException {
      rethrow;
    } on Object {
      throw HapticServiceException(operation: 'trigger', kind: kind);
    }
  }
}
