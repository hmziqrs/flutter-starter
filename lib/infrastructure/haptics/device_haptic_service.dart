import 'package:flutter/services.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';

/// Production `HapticService` backed by the cross-platform `HapticFeedback`
/// surface from `flutter/services`. A platform-call failure is wrapped in
/// `HapticServiceException`; call sites treat haptics as fire-and-forget and
/// swallow it. Tests/goldens override with `NoopHapticService` instead.
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
