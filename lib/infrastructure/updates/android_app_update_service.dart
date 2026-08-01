import 'package:in_app_update/in_app_update.dart' as iau;
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/async/run_guarded.dart';

class AndroidAppUpdateService implements AppUpdateService {
  AndroidAppUpdateService({AppLogger? logger}) : _logger = logger ?? AppLogger.bootstrap();

  final AppLogger _logger;

  @override
  Future<UpdateAvailability> checkForUpdate() async {
    try {
      final info = await iau.InAppUpdate.checkForUpdate();
      return _mapAvailability(info.updateAvailability);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'app_update.android.check_failed',
        error: error,
        stackTrace: stackTrace,
      );
      return UpdateAvailability.noUpdate;
    }
  }

  @override
  Future<void> launchUpdate({bool immediate = false}) async {
    await runGuarded(
      () async {
        if (immediate) {
          await iau.InAppUpdate.performImmediateUpdate();
          return;
        }
        await iau.InAppUpdate.startFlexibleUpdate();
        await iau.InAppUpdate.completeFlexibleUpdate();
      },
      logger: _logger,
      label: 'app_update.android.launch',
    );
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
