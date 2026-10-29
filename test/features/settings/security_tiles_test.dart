import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_section.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

/// The security rows must never render enabled and silently ignore input
/// (BRAND.md s9, s11): without a passcode they disable with a muted hint,
/// and the auto-lock delay is a picker whose options say what they do.
void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('auto-lock delay is a picker that persists the picked delay', (tester) async {
    _setViewport(tester);
    final store = InMemorySettingsStore();
    await tester.pumpWidget(_harness(store: store, passcodeEnabled: true));
    await _settle(tester);

    for (final seconds in [0, 30, 60, 300]) {
      expect(find.byKey(ValueKey('auto-lock-$seconds')), findsOneWidget);
    }

    final oneMinute = find.byKey(const ValueKey('auto-lock-60'));
    await tester.ensureVisible(oneMinute);
    await _settle(tester);
    await tester.tap(oneMinute.hitTestable());
    await _settle(tester);
    expect(store.snapshot[SettingsRepository.autoLockDelayKey], '60');

    await tester.tap(find.byKey(const ValueKey('auto-lock-0')).hitTestable());
    await _settle(tester);
    // "Off" is stored by removing the key (the repository's zero contract).
    expect(store.snapshot.containsKey(SettingsRepository.autoLockDelayKey), isFalse);
    expect(
      ProviderScope.containerOf(
        tester.element(find.byKey(const ValueKey('auto-lock-0'))),
      ).read(settingsControllerProvider).autoLockDelaySeconds,
      0,
    );
  });

  testWidgets('without a passcode, auto-lock delay is a quiet inert row with the hint', (
    tester,
  ) async {
    _setViewport(tester);
    final store = InMemorySettingsStore();
    await tester.pumpWidget(_harness(store: store));
    await _settle(tester);

    expect(find.byKey(const ValueKey('settings-auto-lock-inert')), findsOneWidget);
    // Both passcode-gated rows (this one and lock-on-background) carry the
    // same hint on this page.
    expect(find.text('Set up a passcode to use this.'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('auto-lock-60')), findsNothing);
    expect(store.snapshot.containsKey(SettingsRepository.autoLockDelayKey), isFalse);
  });

  testWidgets('lock-on-background is visibly disabled without a passcode', (tester) async {
    _setViewport(tester);
    final store = InMemorySettingsStore();
    await tester.pumpWidget(_harness(store: store));
    await _settle(tester);

    final toggle = find.byKey(const ValueKey('settings-toggle-lock-on-background'));
    await tester.ensureVisible(toggle);
    await _settle(tester);
    expect(tester.widget<FSwitch>(toggle).onChange, isNull, reason: 'no passcode, no lock');
    // Shared hint: this row and the inert auto-lock row both carry it.
    expect(find.text('Set up a passcode to use this.'), findsNWidgets(2));

    // warnIfMissed: false — a disabled control may not be hit-testable at
    // all, which is fine; the point is the tap changes nothing.
    await tester.tap(toggle, warnIfMissed: false);
    await _settle(tester);
    expect(tester.widget<FSwitch>(toggle).value, isFalse);
    expect(store.snapshot.containsKey(SettingsRepository.lockOnBackgroundKey), isFalse);
  });

  testWidgets('lock-on-background toggles and persists once a passcode is set', (tester) async {
    _setViewport(tester);
    final store = InMemorySettingsStore();
    await tester.pumpWidget(_harness(store: store, passcodeEnabled: true));
    await _settle(tester);

    final toggle = find.byKey(const ValueKey('settings-toggle-lock-on-background'));
    await tester.ensureVisible(toggle);
    await _settle(tester);
    expect(tester.widget<FSwitch>(toggle).onChange, isNotNull);

    await tester.tap(toggle.hitTestable());
    await _settle(tester);
    expect(tester.widget<FSwitch>(toggle).value, isTrue);
    expect(store.snapshot[SettingsRepository.lockOnBackgroundKey], 'true');
  });

  testWidgets('biometric unlock is disabled with the unavailable hint when the device cannot', (
    tester,
  ) async {
    _setViewport(tester);
    final store = InMemorySettingsStore();
    await tester.pumpWidget(
      _harness(store: store, biometricsAvailable: false, passcodeEnabled: true),
    );
    await _settle(tester);

    final toggle = find.byKey(const ValueKey('settings-toggle-biometric'));
    await tester.ensureVisible(toggle);
    await _settle(tester);
    expect(tester.widget<FSwitch>(toggle).onChange, isNull);
    expect(
      find.text(
        'Biometric unlock is not available on this device. Use your device credentials instead.',
      ),
      findsOneWidget,
    );

    // warnIfMissed: false — a disabled control may not be hit-testable.
    await tester.tap(toggle, warnIfMissed: false);
    await _settle(tester);
    expect(store.snapshot.containsKey(SettingsRepository.biometricUnlockKey), isFalse);
  });

  testWidgets('biometric unlock toggles and persists when the device can', (tester) async {
    _setViewport(tester);
    final store = InMemorySettingsStore();
    await tester.pumpWidget(_harness(store: store, passcodeEnabled: true));
    await _settle(tester);

    final toggle = find.byKey(const ValueKey('settings-toggle-biometric'));
    await tester.ensureVisible(toggle);
    await _settle(tester);
    expect(tester.widget<FSwitch>(toggle).onChange, isNotNull);

    await tester.tap(toggle.hitTestable());
    await _settle(tester);
    expect(tester.widget<FSwitch>(toggle).value, isTrue);
    expect(store.snapshot[SettingsRepository.biometricUnlockKey], 'true');
  });
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _harness({
  required InMemorySettingsStore store,
  bool passcodeEnabled = false,
  int autoLockDelaySeconds = 0,
  bool biometricsAvailable = true,
}) {
  final repository = SettingsRepository(store);
  final initialState = SettingsState(
    themeMode: AppThemeMode.system,
    accent: AppAccent.neutral,
    fontScale: 1,
    localeOverride: AppLocale.en,
    textPreset: AppTextPreset.comfortable,
    spacingVariant: AppSpacingVariant.standard,
    radiusVariant: AppRadiusVariant.rounded,
    passcodeEnabled: passcodeEnabled,
    autoLockDelaySeconds: autoLockDelaySeconds,
  );
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      initialSettingsProvider.overrideWithValue(initialState),
      settingsStoreProvider.overrideWithValue(store),
      biometricAvailabilityProvider.overrideWith(
        (ref) async => biometricsAvailable
            ? const BiometricAvailability.available(
                supportedBiometrics: <BiometricKind>{
                  BiometricKind.fingerprint,
                },
              )
            : const BiometricAvailability.unavailable(),
      ),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(data: theme, child: child ?? const SizedBox.shrink()),
        home: AppLayoutScope(
          builder: (context, _) => SettingsPage(
            section: SettingsSection.privacyAbout,
            onOpenAppearance: () {},
            onOpenLanguage: () {},
            onOpenAccessibility: () {},
            onOpenAccount: () {},
            onOpenSubscription: () {},
            onOpenPrivacyAbout: () {},
            onOpenProfile: () {},
            onOpenLogin: () {},
            onOpenPricing: () {},
            onOpenPasscodeSetup: () {},
            onOpenTerms: () {},
            onOpenPrivacy: () {},
            onOpenLicense: () {},
            loadBuildLabel: () async => 'test-build',
          ),
        ),
      ),
    ),
  );
}
