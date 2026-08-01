import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class IosAppUpdateService implements AppUpdateService {
  const IosAppUpdateService({required this.appleId});

  final String appleId;

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
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // ignored
    }
  }
}
