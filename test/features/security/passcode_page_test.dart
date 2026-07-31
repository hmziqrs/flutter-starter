import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/security/passcode_hasher.dart';
import 'package:starter/features/security/passcode_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

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
            child: FToaster(child: FTooltipGroup(child: child ?? const SizedBox.shrink())),
          ),
        );
      },
    ),
  );
}

ProviderScope _scope({required Widget child}) {
  return ProviderScope(
    overrides: [
      secureStoreProvider.overrideWithValue(InMemorySecureStore()),
      passcodeHasherProvider.overrideWithValue(const CryptoPasscodeHasher()),
    ],
    child: _localizedApp(home: child),
  );
}

Future<void> _settle(WidgetTester tester) async {
  // pumpAndSettle never settles motion-guarded pages (repeating timers), so pump bounded frames.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('entry surface renders the title, body, and unlock action', (tester) async {
    await tester.pumpWidget(
      _scope(
        child: const PasscodePage(
          mode: PasscodePageMode.entry,
          onUnlocked: _noop,
          onDisable: _noop,
        ),
      ),
    );
    await _settle(tester);

    final translations = tester.element(find.byType(PasscodePage)).t.security.passcode;
    expect(find.text(translations.enterTitle), findsWidgets);
    expect(find.text(translations.enterBody), findsOneWidget);
  });

  testWidgets('a correct confirm in setup fires onSetupComplete', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      _scope(
        child: PasscodePage(
          mode: PasscodePageMode.setup,
          onUnlocked: _noop,
          onSetupComplete: () => completed += 1,
        ),
      ),
    );
    await _settle(tester);

    await tester.enterText(find.byKey(const ValueKey('passcode-setup-entry')), '1234');
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('passcode-setup-confirm')), '1234');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('passcode-setup-submit')));
    await _settle(tester);

    expect(completed, 1, reason: 'a matching confirm stores the passcode and completes setup');
  });

  testWidgets('a mismatched confirm surfaces the mismatch error and clears confirm', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scope(
        child: const PasscodePage(
          mode: PasscodePageMode.setup,
          onUnlocked: _noop,
          onSetupComplete: _noop,
        ),
      ),
    );
    await _settle(tester);

    final translations = tester.element(find.byType(PasscodePage)).t.security.passcode;
    await tester.enterText(find.byKey(const ValueKey('passcode-setup-entry')), '1234');
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('passcode-setup-confirm')), '4321');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('passcode-setup-submit')));
    await _settle(tester);

    expect(find.text(translations.mismatch), findsOneWidget);
    final confirm = tester.widget<TextField>(find.byKey(const ValueKey('passcode-setup-confirm')));
    expect(confirm.controller!.text, isEmpty, reason: 'confirm is cleared on mismatch');
  });

  testWidgets('entry with the correct passcode fires onUnlocked', (tester) async {
    var unlocked = 0;
    const hasher = CryptoPasscodeHasher();
    final salt = hasher.generateSalt();
    final hash = hasher.saltAndHash('2580', salt);
    final store = InMemorySecureStore(
      seed: {
        PasscodeController.saltKey: salt,
        PasscodeController.hashKey: hash,
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStoreProvider.overrideWithValue(store),
          passcodeHasherProvider.overrideWithValue(const CryptoPasscodeHasher()),
        ],
        child: _localizedApp(
          home: PasscodePage(
            mode: PasscodePageMode.entry,
            onUnlocked: () => unlocked += 1,
          ),
        ),
      ),
    );
    await _settle(tester);

    await tester.enterText(find.byKey(const ValueKey('passcode-entry-field')), '2580');
    await _settle(tester);

    expect(unlocked, 1, reason: 'a correct entry unlocks and never gates on animation');
  });
}

void _noop() {}
