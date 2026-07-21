import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

void main() {
  test('settings persistence keys are explicit and unique', () {
    expect(SettingsRepository.persistedKeys.toSet(), {
      'appearance.theme_mode',
      'appearance.accent',
      'appearance.font_scale',
      'localization.locale',
    });
    expect(
      SettingsRepository.persistedKeys,
      hasLength(SettingsRepository.persistedKeys.toSet().length),
    );
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesAsyncPlatform? previousPlatform;

  setUp(() {
    previousPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() => SharedPreferencesAsyncPlatform.instance = previousPlatform);

  test('reconstructed production dependencies load persisted settings', () async {
    final first = await AppDependencies.production(AppLogger.bootstrap());
    const expected = SettingsState(
      themeMode: AppThemeMode.dark,
      accent: AppAccent.violet,
      fontScale: 1.35,
      localeOverride: AppLocale.zhHans,
    );

    await first.settingsRepository.save(expected);
    final reconstructed = await AppDependencies.production(AppLogger.bootstrap());

    expect(reconstructed.initialSettings, expected);
  });
}
