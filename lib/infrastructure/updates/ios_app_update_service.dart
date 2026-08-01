import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/async/run_guarded.dart';
import 'package:url_launcher/url_launcher.dart';

class IosAppUpdateService implements AppUpdateService {
  IosAppUpdateService({required this.appleId, AppLogger? logger})
    : _logger = logger ?? AppLogger.bootstrap();

  final String appleId;

  final AppLogger _logger;

  @override
  Future<UpdateAvailability> checkForUpdate() async {
    return UpdateAvailability.noUpdate;
  }

  @override
  Future<void> launchUpdate({bool immediate = false}) async {
    final id = appleId.trim();
    if (id.isEmpty) {
      return;
    }
    final uri = Uri.tryParse('https://apps.apple.com/app/id$id');
    if (uri == null) {
      return;
    }
    await runGuarded(
      () => launchUrl(uri, mode: LaunchMode.externalApplication),
      logger: _logger,
      label: 'app_update.ios.launch',
    );
  }
}
