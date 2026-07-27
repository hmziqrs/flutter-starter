import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';

void main() {
  group('SettingsRepository onboarding flag', () {
    test('persists completed onboarding as "true" and round-trips', () async {
      final store = InMemorySettingsStore();
      final repository = SettingsRepository(store);

      await repository.save(
        const SettingsState.defaults().copyWith(hasCompletedOnboarding: true),
      );

      // The non-default value is persisted; the rest of the appearance defaults
      // remain at their cold-start writes (themeMode/accent/fontScale).
      expect(store.snapshot[SettingsRepository.onboardingKey], 'true');

      final loaded = await repository.load();
      expect(loaded.hasCompletedOnboarding, isTrue);
    });

    test('removes the onboarding key when persisting the default false value', () async {
      final store = InMemorySettingsStore(
        seed: {
          SettingsRepository.onboardingKey: 'true',
        },
      );
      final repository = SettingsRepository(store);

      await repository.save(const SettingsState.defaults());

      expect(store.snapshot.containsKey(SettingsRepository.onboardingKey), isFalse);

      final loaded = await repository.load();
      expect(loaded.hasCompletedOnboarding, isFalse);
    });

    test('treats a missing onboarding key as incomplete on cold start', () async {
      final repository = SettingsRepository(InMemorySettingsStore());

      expect((await repository.load()).hasCompletedOnboarding, isFalse);
    });

    test('treats any non-"true" stored value as incomplete (legacy resilience)', () async {
      final store = InMemorySettingsStore(
        seed: {
          SettingsRepository.onboardingKey: 'false',
        },
      );
      final repository = SettingsRepository(store);

      expect((await repository.load()).hasCompletedOnboarding, isFalse);
    });

    test('onboardingKey is part of persistedKeys so resets clear it', () {
      expect(
        SettingsRepository.persistedKeys,
        contains(SettingsRepository.onboardingKey),
      );
    });
  });

  group('SettingsController.markOnboardingComplete', () {
    test('optimistically flips the in-memory flag and persists "true"', () async {
      final store = InMemorySettingsStore();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
          initialSettingsProvider.overrideWithValue(const SettingsState.defaults()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(settingsControllerProvider.notifier);
      expect(
        container.read(settingsControllerProvider).hasCompletedOnboarding,
        isFalse,
      );

      await controller.markOnboardingComplete();

      expect(
        container.read(settingsControllerProvider).hasCompletedOnboarding,
        isTrue,
      );
      expect(store.snapshot[SettingsRepository.onboardingKey], 'true');
    });

    test('rolls back the in-memory flag when persistence fails', () async {
      final store = InMemorySettingsStore()..failWrites = true;
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
          initialSettingsProvider.overrideWithValue(const SettingsState.defaults()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(settingsControllerProvider.notifier);

      await expectLater(
        controller.markOnboardingComplete(),
        throwsA(isA<SettingsFailure>()),
      );
      expect(
        container.read(settingsControllerProvider).hasCompletedOnboarding,
        isFalse,
      );
    });

    test('preserves the rest of the settings state when marking complete', () async {
      const seed = SettingsState(
        themeMode: AppThemeMode.dark,
        accent: AppAccent.violet,
        fontScale: 1.35,
        textPreset: AppTextPreset.comfortable,
        localeOverride: null,
      );
      final store = InMemorySettingsStore();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
          initialSettingsProvider.overrideWithValue(seed),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsControllerProvider.notifier).markOnboardingComplete();

      final state = container.read(settingsControllerProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.accent, AppAccent.violet);
      expect(state.fontScale, 1.35);
      expect(state.hasCompletedOnboarding, isTrue);
    });
  });

  group('SettingsState onboarding field', () {
    test('default is false and equality includes the flag', () {
      const defaults = SettingsState.defaults();
      expect(defaults.hasCompletedOnboarding, isFalse);

      final marked = defaults.copyWith(hasCompletedOnboarding: true);
      expect(marked.hasCompletedOnboarding, isTrue);
      expect(defaults == marked, isFalse);
      expect(defaults.hashCode == marked.hashCode, isFalse);
    });
  });

  test('InMemorySettingsStore seed surfaces the onboarding key on snapshot', () {
    final store = InMemorySettingsStore(
      seed: {
        SettingsRepository.onboardingKey: 'true',
      },
    );
    expect(store.snapshot[SettingsRepository.onboardingKey], 'true');
  });
}
