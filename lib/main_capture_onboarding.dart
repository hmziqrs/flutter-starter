import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/devtools/real_inspector_host.dart';

/// Temporary verification entrypoint: clears persisted app state before the
/// normal bootstrap so a cold start exercises the real splash -> onboarding
/// flow for UI captures. `CAPTURE_SEED_THEME_MODE=light|system|dark` writes
/// the matching `AppThemeMode` name into the settings store after the clear
/// (values persisted by `SettingsRepository`); set
/// `CAPTURE_RESET_STATE=false` to keep existing state and only reseed the
/// theme. Everything else matches lib/main_capture.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const resetState = bool.fromEnvironment('CAPTURE_RESET_STATE', defaultValue: true);
  const seedThemeMode = String.fromEnvironment('CAPTURE_SEED_THEME_MODE');
  const seedFontScale = String.fromEnvironment('CAPTURE_SEED_FONT_SCALE');
  final preferences = SharedPreferencesAsync();
  if (resetState) {
    await preferences.clear();
  }
  if (seedThemeMode.isNotEmpty) {
    await preferences.setString('appearance.theme_mode', seedThemeMode);
  }
  if (seedFontScale.isNotEmpty) {
    await preferences.setString('appearance.font_scale', seedFontScale);
  }
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
