import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  test('round-trips every supported setting', () async {
    final store = InMemorySettingsStore();
    final repository = SettingsRepository(store);
    const expected = SettingsState(
      themeMode: AppThemeMode.dark,
      accent: AppAccent.violet,
      fontScale: 1.35,
      localeOverride: AppLocale.zhHans,
    );

    await repository.save(expected);

    expect(await repository.load(), expected);
  });

  test('removing a locale override returns to system locale', () async {
    final store = InMemorySettingsStore();
    final repository = SettingsRepository(store);
    const localized = SettingsState(
      themeMode: AppThemeMode.light,
      accent: AppAccent.green,
      fontScale: 1,
      localeOverride: AppLocale.ar,
    );

    await repository.save(localized);
    await repository.save(localized.copyWith(followSystemLocale: true));

    expect((await repository.load()).localeOverride, isNull);
  });

  test('falls back safely when every stored value is invalid', () async {
    final repository = SettingsRepository(_InvalidValueStore());

    expect(await repository.load(), const SettingsState.defaults());
  });

  test('maps store read failures without exposing plugin errors', () async {
    final store = InMemorySettingsStore()..failReads = true;
    final repository = SettingsRepository(store);

    expect(repository.load, throwsA(isA<SettingsFailure>()));
  });

  test('maps store write failures without exposing plugin errors', () async {
    final store = InMemorySettingsStore()..failWrites = true;
    final repository = SettingsRepository(store);

    expect(
      () => repository.save(const SettingsState.defaults()),
      throwsA(isA<SettingsFailure>()),
    );
  });
}

final class _InvalidValueStore implements SettingsStore {
  @override
  Future<String?> readString(String key) async => 'invalid';

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}
