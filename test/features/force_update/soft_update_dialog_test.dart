import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/features/force_update/soft_update_dialog.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

const _state = ForceUpdateState(
  latestVersion: '1.5.0',
  storeUrl: 'https://example.test/store',
);

Widget _localizedApp({required Widget home}) {
  return ProviderScope(
    child: TranslationProvider(
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
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('SoftUpdateSnooze math', () {
    test('encode produces a future ISO-8601 deadline', () {
      final encoded = SoftUpdateSnooze.encode(
        at: DateTime.utc(2026, 1, 1, 12),
        duration: const Duration(hours: 1),
      );
      expect(encoded, '2026-01-01T13:00:00.000Z');
    });

    test('isSnoozed is true only while the deadline is in the future', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final encoded = SoftUpdateSnooze.encode(
        at: now,
        duration: const Duration(hours: 1),
      );
      expect(SoftUpdateSnooze.isSnoozed(encoded, now: now), isTrue);
      expect(
        SoftUpdateSnooze.isSnoozed(
          encoded,
          now: now.add(const Duration(hours: 2)),
        ),
        isFalse,
      );
    });

    test('isSnoozed tolerates null and garbage', () {
      expect(SoftUpdateSnooze.isSnoozed(null), isFalse);
      expect(SoftUpdateSnooze.isSnoozed('not-a-date'), isFalse);
    });

    test('key is the documented settings key', () {
      expect(SoftUpdateSnooze.key, 'update.snoozed_until');
    });
  });

  testWidgets('SoftUpdateCard renders title, body and both actions', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        home: Scaffold(
          body: SoftUpdateCard(
            state: _state,
            onUpdate: () {},
            onLater: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final translations = tester.element(find.byType(SoftUpdateCard)).t;
    expect(find.text(translations.softUpdate.title), findsOneWidget);
    expect(find.text(translations.softUpdate.body), findsOneWidget);
    expect(find.text(translations.softUpdate.update), findsOneWidget);
    expect(find.text(translations.softUpdate.later), findsOneWidget);
  });

  testWidgets('showSoftUpdateDialog wraps the card in EscapeDismissibleOverlay', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        home: Scaffold(
          body: Center(
            child: FButton(
              key: const ValueKey('trigger'),
              onPress: () => showSoftUpdateDialog(
                tester.element(find.byKey(const ValueKey('trigger'))),
                state: _state,
                onUpdate: () {},
                onLater: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('trigger')));
    await _pumpFrames(tester);

    expect(find.byType(EscapeDismissibleOverlay), findsOneWidget);
    expect(find.byKey(const ValueKey('soft-update-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('soft-update-later')), findsOneWidget);
    expect(find.byKey(const ValueKey('soft-update-update')), findsOneWidget);
  });

  testWidgets('Later dismisses the dialog and invokes the callback', (tester) async {
    var laterPressed = 0;
    await tester.pumpWidget(
      _localizedApp(
        home: _DialogHost(
          state: _state,
          onLater: () => laterPressed += 1,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('open-dialog')));
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const ValueKey('soft-update-later')));
    await _pumpFrames(tester);

    expect(laterPressed, 1);
    expect(find.byKey(const ValueKey('soft-update-dialog')), findsNothing);
  });

  testWidgets('Update dismisses the dialog and invokes the callback', (tester) async {
    var updatePressed = 0;
    await tester.pumpWidget(
      _localizedApp(
        home: _DialogHost(
          state: _state,
          onUpdate: () => updatePressed += 1,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('open-dialog')));
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const ValueKey('soft-update-update')));
    await _pumpFrames(tester);

    expect(updatePressed, 1);
    expect(find.byKey(const ValueKey('soft-update-dialog')), findsNothing);
  });
}

class _DialogHost extends StatelessWidget {
  const _DialogHost({required this.state, this.onUpdate, this.onLater});

  final ForceUpdateState state;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FButton(
          key: const ValueKey('open-dialog'),
          onPress: () {
            unawaited(
              showSoftUpdateDialog(
                context,
                state: state,
                onUpdate: onUpdate ?? () {},
                onLater: onLater ?? () {},
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}
