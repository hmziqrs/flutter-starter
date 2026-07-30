import 'package:in_app_update/in_app_update.dart' as iau;
import 'package:starter/infrastructure/updates/app_update_service.dart';

/// Production [AppUpdateService] for Android, backed by the `in_app_update`
/// plugin (Google Play in-app update). Constructed only on Android; other
/// platforms use a different adapter.
///
/// [checkForUpdate] maps the plugin's result and never reports
/// [UpdateAvailability.required] — the OS-store path is a non-blocking soft
/// nudge; the server `VersionGateStore` owns the hard/soft block.
///
/// The real plugin requires a physical Android device with Play Services and
/// a published Play listing, so this path is not exercised in CI; automated
/// coverage uses `NoopAppUpdateService`.
class AndroidAppUpdateService implements AppUpdateService {
  const AndroidAppUpdateService();

  @override
  Future<UpdateAvailability> checkForUpdate() async {
    try {
      final info = await iau.InAppUpdate.checkForUpdate();
      return _mapAvailability(info.updateAvailability);
    } on Object {
      // Plugin error / missing Play Services — degrade honestly.
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

  /// Maps the plugin's [iau.UpdateAvailability] to the typed enum. `required`
  /// is never produced (the OS-store path is non-blocking by design).
  static UpdateAvailability _mapAvailability(iau.UpdateAvailability availability) {
    return switch (availability) {
      iau.UpdateAvailability.updateAvailable ||
      iau.UpdateAvailability.developerTriggeredUpdateInProgress => UpdateAvailability.available,
      iau.UpdateAvailability.updateNotAvailable ||
      iau.UpdateAvailability.unknown => UpdateAvailability.noUpdate,
    };
  }
}
