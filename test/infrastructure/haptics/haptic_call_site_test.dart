import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/cases/haptics_gallery_cases.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/infrastructure/haptics/noop_haptic_service.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

Widget _hapticApp({
  required NoopHapticService service,
  required SettingsState settings,
  required bool disableAnimations,
}) {
  final hapticCase = buildHapticsGalleryCases().single;
  return ProviderScope(
    overrides: [
      hapticServiceProvider.overrideWithValue(service),
      initialSettingsProvider.overrideWithValue(settings),
    ],
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Builder(builder: hapticCase.build),
            locale: localeData.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            builder: (context, child) => FTheme(
              data: theme,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
                child: FToaster(
                  child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

const ValueKey<String> _selectionKey = ValueKey('haptics-trigger-selection');

Future<void> _settleFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

SettingsState _state({required bool hapticsEnabled}) {
  return const SettingsState.defaults().copyWith(
    hasCompletedOnboarding: true,
    hapticsEnabled: hapticsEnabled,
  );
}

void main() {
  testWidgets('fires when haptics enabled and animations allowed', (tester) async {
    final service = NoopHapticService();
    await tester.pumpWidget(
      _hapticApp(
        service: service,
        settings: _state(hapticsEnabled: true),
        disableAnimations: false,
      ),
    );
    await _settleFrames(tester);

    await tester.tap(find.byKey(_selectionKey));
    await _settleFrames(tester);

    expect(service.lastKind, HapticKind.selection);
    expect(service.callCount, 1);
  });

  testWidgets('does NOT fire when hapticsEnabled is false (user opt-out)', (tester) async {
    final service = NoopHapticService();
    await tester.pumpWidget(
      _hapticApp(
        service: service,
        settings: _state(hapticsEnabled: false),
        disableAnimations: false,
      ),
    );
    await _settleFrames(tester);

    await tester.tap(find.byKey(_selectionKey));
    await _settleFrames(tester);

    expect(service.lastKind, isNull);
    expect(service.callCount, 0);
  });

  testWidgets('does NOT fire when reduce-motion (disableAnimationsOf) is true', (tester) async {
    final service = NoopHapticService();
    await tester.pumpWidget(
      _hapticApp(service: service, settings: _state(hapticsEnabled: true), disableAnimations: true),
    );
    await _settleFrames(tester);

    await tester.tap(find.byKey(_selectionKey));
    await _settleFrames(tester);

    expect(service.lastKind, isNull);
    expect(service.callCount, 0);
  });

  testWidgets('renders a translated button for every HapticKind', (tester) async {
    await tester.pumpWidget(
      _hapticApp(
        service: NoopHapticService(),
        settings: _state(hapticsEnabled: true),
        disableAnimations: false,
      ),
    );
    await _settleFrames(tester);

    for (final kind in HapticKind.values) {
      expect(find.byKey(ValueKey('haptics-trigger-${kind.name}')), findsOneWidget);
    }
  });
}
