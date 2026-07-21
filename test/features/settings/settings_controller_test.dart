import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';

void main() {
  test('updates and persists appearance settings', () async {
    final repository = SettingsRepository(InMemorySettingsStore());
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        initialSettingsProvider.overrideWithValue(const SettingsState.defaults()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(settingsControllerProvider.notifier);
    await controller.setThemeMode(AppThemeMode.dark);
    await controller.setAccent(AppAccent.blue);
    await controller.setFontScale(1.3);

    expect(
      container.read(settingsControllerProvider),
      const SettingsState(
        themeMode: AppThemeMode.dark,
        accent: AppAccent.blue,
        fontScale: 1.3,
        localeOverride: null,
      ),
    );
    expect(await repository.load(), container.read(settingsControllerProvider));
  });

  test('reverts an optimistic update when persistence fails', () async {
    final store = InMemorySettingsStore()..failWrites = true;
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(settingsControllerProvider.notifier);

    await expectLater(controller.setAccent(AppAccent.rose), throwsA(isA<SettingsFailure>()));
    expect(container.read(settingsControllerProvider), const SettingsState.defaults());
  });
}
