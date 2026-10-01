import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/devtools/real_inspector_host.dart';

Future<void> main() => bootstrapApplication(
  inspectorHost: (config) => RealInspectorHost(
    developmentToolsEnabled: config.developmentToolsEnabled,
    backendBaseUrl: config.backendBaseUrl,
  ),
);
