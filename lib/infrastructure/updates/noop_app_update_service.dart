import 'package:starter/infrastructure/updates/app_update_service.dart';

/// Deterministic, honest "no store update" [AppUpdateService].
///
/// The composition root selects this adapter for web, unsupported platforms,
/// and integration-test / golden runs (keyed off `PlatformCapabilities`, never
/// a global) so the starter stays green and goldens stay stable without ever
/// triggering the Play in-app update plugin or opening the App Store. Per the
/// no-backend / honest-feedback contracts (C2 / C13) it returns
/// [UpdateAvailability.noUpdate] from [checkForUpdate] and no-ops
/// [launchUpdate] — it **never fakes an available update or a successful
/// install**. There is no optional real impl behind it; the production path on
/// a supported platform uses `AndroidAppUpdateService` or
/// `IosAppUpdateService` instead.
class NoopAppUpdateService implements AppUpdateService {
  const NoopAppUpdateService();

  @override
  Future<UpdateAvailability> checkForUpdate() async => UpdateAvailability.noUpdate;

  @override
  Future<void> launchUpdate({bool immediate = false}) async {
    // Honest no-op: there is no store to launch, and the contract forbids a
    // faked success state. The [immediate] flag is accepted for port parity.
  }
}
