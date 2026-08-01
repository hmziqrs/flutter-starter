import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/security/biometric_lock_page.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

class _PinnedBiometricUnlockController extends BiometricUnlockController {
  _PinnedBiometricUnlockController(this.pinnedState);

  final BiometricLockState pinnedState;

  @override
  BiometricLockState build() => pinnedState;
}

class _StubAuthenticator implements BiometricAuthenticator {
  _StubAuthenticator({required this.availability, this.authenticateResult = true});

  BiometricAvailability availability;
  bool authenticateResult;

  @override
  Future<BiometricAvailability> checkAvailability() async => availability;

  @override
  Future<bool> authenticate({required String localizedReason}) async => authenticateResult;
}

Widget _localizedApp({required Widget home}) {
  return TranslationProvider(
    child: Builder(
      builder: (context) {
        final localeData = TranslationProvider.of(context);
        final theme = generated.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: home,
          locale: localeData.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          builder: (context, child) => FTheme(
            data: theme,
            child: FToaster(
              child: FTooltipGroup(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('renders the locked prompt with the unlock action and copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricAuthenticatorProvider.overrideWithValue(const NoopBiometricAuthenticator()),
          biometricUnlockControllerProvider.overrideWith(
            () => _PinnedBiometricUnlockController(const BiometricLockLocked()),
          ),
        ],
        child: _localizedApp(
          home: const BiometricLockPage(onUnlocked: _noop, onUseFallback: _noop),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final translations = tester.element(find.byType(BiometricLockPage)).t.security.biometric;
    expect(find.text(translations.lockTitle), findsOneWidget);
    expect(find.text(translations.lockBody), findsOneWidget);
    expect(find.text(translations.unlock), findsOneWidget);
    expect(find.text(translations.useFallback), findsNothing);
  });

  testWidgets('renders the unavailable surface with the fallback action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricAuthenticatorProvider.overrideWithValue(const NoopBiometricAuthenticator()),
          biometricUnlockControllerProvider.overrideWith(
            () => _PinnedBiometricUnlockController(const BiometricLockUnavailable()),
          ),
        ],
        child: _localizedApp(
          home: const BiometricLockPage(onUnlocked: _noop, onUseFallback: _noop),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final translations = tester.element(find.byType(BiometricLockPage)).t.security.biometric;
    expect(find.text(translations.unavailableTitle), findsOneWidget);
    expect(find.text(translations.unavailableBody), findsOneWidget);
    expect(find.text(translations.unlock), findsNothing);
    expect(find.text(translations.useFallback), findsOneWidget);
  });

  testWidgets('a successful OS prompt fires onUnlocked (navigation, never faked)', (tester) async {
    var unlocked = 0;
    final stub = _StubAuthenticator(
      availability: const BiometricAvailability.available(
        supportedBiometrics: {BiometricKind.face},
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [biometricAuthenticatorProvider.overrideWithValue(stub)],
        child: _localizedApp(
          home: BiometricLockPage(onUnlocked: () => unlocked += 1, onUseFallback: _noop),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byKey(const ValueKey('biometric-lock-unlock')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('biometric-lock-unlock')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(unlocked, 1);
  });

  testWidgets('a failed OS prompt shows the retry alert and does not navigate', (tester) async {
    var unlocked = 0;
    final stub = _StubAuthenticator(
      availability: const BiometricAvailability.available(
        supportedBiometrics: {BiometricKind.face},
      ),
      authenticateResult: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [biometricAuthenticatorProvider.overrideWithValue(stub)],
        child: _localizedApp(
          home: BiometricLockPage(onUnlocked: () => unlocked += 1, onUseFallback: _noop),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.tap(find.byKey(const ValueKey('biometric-lock-unlock')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(unlocked, 0);
    expect(find.byKey(const ValueKey('biometric-lock-failure')), findsOneWidget);
  });
}

void _noop() {}
