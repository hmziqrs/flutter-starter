import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

// iOS forbids in-app update checks; App Store policy only allows nudging to the store.
class IosAppUpdateService implements AppUpdateService {
  const IosAppUpdateService({required this.appleId});

  final String appleId;

  @override
  Future<UpdateAvailability> checkForUpdate() async {
    // Newer-build nudges route through `VersionGateStore`.
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
      // Store deep-link is best-effort; the soft nudge stays dismissible.
    }
  }
}
