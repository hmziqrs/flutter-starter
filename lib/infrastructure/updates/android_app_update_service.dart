import 'package:in_app_update/in_app_update.dart' as iau;
import 'package:starter/infrastructure/updates/app_update_service.dart';

/// Production [AppUpdateService] for Android, backed by the `in_app_update`
/// plugin (Google Play in-app update).
///
/// Constructed in `AppDependencies.production` (the composition root) **only**
/// on Android (selected from `PlatformCapabilities`); iOS / web / unsupported /
/// integration-test runs use a different adapter. The plugin is never referenced
/// outside this adapter — every consumer reads the typed
/// [UpdateAvailability] surface (C2: no widget calls a plugin directly).
///
/// Both methods degrade honestly inside `try/on Object` (C13: never fake
/// success). [checkForUpdate] maps the plugin's [iau.UpdateAvailability] to the
/// typed enum and **never** reports [UpdateAvailability.required] — the
/// OS-store path is the non-blocking soft nudge; the server
/// [`VersionGateStore`] owns the hard/soft block (see the feature spec's
/// update-gate coordination and contracts C5). An `unknown` Play result
/// degrades to [UpdateAvailability.noUpdate] rather than fabricating
/// availability.
///
/// **Testability:** the real `in_app_update` plugin requires a physical Android
/// device with Play Services and a published Play listing, so this path is
/// **not** exercised in CI. Automated coverage uses `NoopAppUpdateService`; the
/// `/dev/diagnostics` manual trigger is the on-device verification seam (see the
/// feature spec Risks).
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
      // Flexible flow: start the background download, then install once ready.
      await iau.InAppUpdate.startFlexibleUpdate();
      await iau.InAppUpdate.completeFlexibleUpdate();
    } on Object {
      // Store-flow failure is best-effort and never breaks the calling UI; the
      // soft nudge stays dismissible, so swallowing is honest (no faked success
      // state is returned to the caller).
    }
  }

  /// Maps the plugin's [iau.UpdateAvailability] to the typed enum. Exhaustive
  /// so a future plugin variant is handled explicitly here. `required` is never
  /// produced (the OS-store path is non-blocking by design).
  static UpdateAvailability _mapAvailability(iau.UpdateAvailability availability) {
    return switch (availability) {
      iau.UpdateAvailability.updateAvailable ||
      iau.UpdateAvailability.developerTriggeredUpdateInProgress => UpdateAvailability.available,
      iau.UpdateAvailability.updateNotAvailable ||
      iau.UpdateAvailability.unknown => UpdateAvailability.noUpdate,
    };
  }
}
