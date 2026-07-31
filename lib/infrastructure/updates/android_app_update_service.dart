import 'package:in_app_update/in_app_update.dart' as iau;
import 'package:starter/infrastructure/updates/app_update_service.dart';

/// The plugin needs a physical device with Play Services + a Play listing.
class AndroidAppUpdateService implements AppUpdateService {
  const AndroidAppUpdateService();

  @override
  Future<UpdateAvailability> checkForUpdate() async {
    try {
      final info = await iau.InAppUpdate.checkForUpdate();
      return _mapAvailability(info.updateAvailability);
    } on Object {
      return UpdateAvailability.noUpdate;
    }
  }

  @override
  Future<void> launchUpdate({bool immediate = false}) async {
    try {
      if (immediate) {
        await iau.InAppUpdate.performImmediateUpdate();
        return;
      }
      await iau.InAppUpdate.startFlexibleUpdate();
      await iau.InAppUpdate.completeFlexibleUpdate();
    } on Object {
      // Store-flow failure is best-effort; the soft nudge stays dismissible.
    }
  }

  static UpdateAvailability _mapAvailability(iau.UpdateAvailability availability) {
    return switch (availability) {
      iau.UpdateAvailability.updateAvailable ||
      iau.UpdateAvailability.developerTriggeredUpdateInProgress => UpdateAvailability.available,
      iau.UpdateAvailability.updateNotAvailable ||
      iau.UpdateAvailability.unknown => UpdateAvailability.noUpdate,
    };
  }
}
