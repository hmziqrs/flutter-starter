import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Production [AppUpdateService] for iOS, backed by `url_launcher` deep-linking
/// to the App Store listing.
///
/// Constructed in `AppDependencies.production` (the composition root) **only**
/// on iOS (selected from `PlatformCapabilities`); Android uses
/// `AndroidAppUpdateService`; web / unsupported / integration-test runs use
/// `NoopAppUpdateService`. `url_launcher` is never referenced outside this
/// adapter — every consumer reads the typed [UpdateAvailability] surface (C2:
/// no widget calls a plugin directly).
///
/// Both methods degrade honestly inside `try/on Object` (C13: never fake
/// success). iOS App Store policy provides **no** programmatic in-app update
/// check, so [checkForUpdate] always returns [UpdateAvailability.noUpdate] —
/// it never fabricates [UpdateAvailability.available] (the honest outcome; a real "newer build"
/// signal on iOS requires the server [`VersionGateStore`] path). [launchUpdate]
/// opens the App Store listing built from the compile-time Apple ID.
///
/// The Apple ID is **compile-time config, not a secret** (see the feature spec
/// + `AppConfig.iosAppleId`): it is passed via
/// `--dart-define-from-file=config/<env>.json` (`IOS_APPLE_ID`), never
/// hardcoded, and never treated as sensitive.
class IosAppUpdateService implements AppUpdateService {
  const IosAppUpdateService({required this.appleId});

  /// The numeric App Store Apple ID for the app, sourced at the composition
  /// root from compile-time `AppConfig.iosAppleId`. Empty when unset —
  /// [launchUpdate] degrades honestly (the URL cannot be opened).
  final String appleId;

  @override
  Future<UpdateAvailability> checkForUpdate() async {
    // iOS App Store policy forbids a programmatic availability check from
    // inside the app. The honest outcome is noUpdate: never fabricate
    // `available`. A real "newer build" nudge on iOS routes through the server
    // VersionGateStore soft path (see the feature spec's update-gate
    // coordination).
    return UpdateAvailability.noUpdate;
  }

  @override
  Future<void> launchUpdate({bool immediate = false}) async {
    // [immediate] has no iOS equivalent (the App Store owns the install), so it
    // is intentionally ignored here; kept in the signature for port parity.
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
      // Store deep-link is best-effort; the soft nudge stays dismissible, so
      // swallowing is honest (no faked success state is returned to the caller).
    }
  }
}
