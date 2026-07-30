import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Production [AppUpdateService] for iOS, backed by `url_launcher`
/// deep-linking to the App Store listing. Constructed only on iOS; Android
/// uses `AndroidAppUpdateService`; web / unsupported / test runs use
/// `NoopAppUpdateService`.
///
/// The Apple ID is compile-time config, not a secret (`AppConfig.iosAppleId`,
/// `--dart-define-from-file` `IOS_APPLE_ID`).
class IosAppUpdateService implements AppUpdateService {
  const IosAppUpdateService({required this.appleId});

  /// The numeric App Store Apple ID. Empty when unset — [launchUpdate]
  /// degrades (the URL cannot be opened).
  final String appleId;

  @override
  Future<UpdateAvailability> checkForUpdate() async {
    // iOS App Store policy forbids a programmatic availability check from
    // inside the app; a real "newer build" nudge routes through the server
    // VersionGateStore soft path instead.
    return UpdateAvailability.noUpdate;
  }

  @override
  Future<void> launchUpdate({bool immediate = false}) async {
    // [immediate] has no iOS equivalent; kept for port parity.
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
