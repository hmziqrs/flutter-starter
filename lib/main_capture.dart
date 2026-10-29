import 'package:flutter/widgets.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/devtools/real_inspector_host.dart';

/// Temporary verification entrypoint: cold-starts on the shell home route so
/// brand captures are not blocked by a persisted deep-link route (e.g. /login).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final app = await createApplication(
    config,
    initialLocation: '/',
    inspectorHost: RealInspectorHost(
      developmentToolsEnabled: config.developmentToolsEnabled,
      backendBaseUrl: config.backendBaseUrl,
    ),
  );
  runApp(app);
}
