import 'package:starter/infrastructure/updates/app_update_service.dart';

class NoopAppUpdateService implements AppUpdateService {
  const NoopAppUpdateService();

  @override
  Future<UpdateAvailability> checkForUpdate() async => UpdateAvailability.noUpdate;

  @override
  Future<void> launchUpdate({bool immediate = false}) async {}
}
