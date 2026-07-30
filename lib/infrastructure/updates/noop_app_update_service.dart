import 'package:starter/infrastructure/updates/app_update_service.dart';

/// Deterministic "no store update" [AppUpdateService], selected for web,
/// unsupported platforms, and test/golden runs. Never triggers the Play
/// in-app update plugin or the App Store; `AndroidAppUpdateService` /
/// `IosAppUpdateService` are the real impls.
class NoopAppUpdateService implements AppUpdateService {
  const NoopAppUpdateService();

  @override
  Future<UpdateAvailability> checkForUpdate() async => UpdateAvailability.noUpdate;

  @override
  Future<void> launchUpdate({bool immediate = false}) async {}
}
