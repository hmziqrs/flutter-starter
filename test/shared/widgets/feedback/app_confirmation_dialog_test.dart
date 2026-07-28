import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';
import 'package:starter/shared/widgets/feedback/app_confirmation_dialog.dart';

const _openKey = Key('open-dialog');
const _dialogKey = Key('app-confirmation-dialog');
const _actionKey = Key('app-confirmation-action');
const _cancelKey = Key('app-confirmation-cancel');

void main() {
  group('AppConfirmationDialog', () {
    group('ConfirmationIntent.confirm', () {
      testWidgets('renders localized common.confirm / common.cancel labels', (tester) async {
        await tester.pumpWidget(
          _harness(child: const _DialogHost(intent: ConfirmationIntent.confirm)),
        );
        await tester.pump();

        await tester.tap(find.byKey(_openKey));
        await _pumpFrames(tester);

        final translations = tester.element(find.byType(_DialogHost)).t;
        expect(find.byKey(_dialogKey), findsOneWidget);
        expect(find.text('Confirm Title'), findsOneWidget);
        expect(find.text('Confirm Body'), findsOneWidget);
        expect(find.text(translations.common.cancel), findsOneWidget);
        expect(find.text(translations.common.confirm), findsOneWidget);
      });

      testWidgets('confirm action returns true and closes the dialog', (tester) async {
        final capture = _ResultCapture();
        await tester.pumpWidget(
          _harness(
            child: _DialogHost(intent: ConfirmationIntent.confirm, onResult: capture.record),
          ),
        );
        await tester.pump();

        await tester.tap(find.byKey(_openKey));
        await _pumpFrames(tester);

        await tester.tap(find.byKey(_actionKey));
        await _pumpFrames(tester);

        expect(capture.value, isTrue);
        expect(find.byKey(_dialogKey), findsNothing);
      });

      testWidgets('cancel action returns false and closes the dialog', (tester) async {
        final capture = _ResultCapture();
        await tester.pumpWidget(
          _harness(
            child: _DialogHost(intent: ConfirmationIntent.confirm, onResult: capture.record),
          ),
        );
        await tester.pump();

        await tester.tap(find.byKey(_openKey));
        await _pumpFrames(tester);

        await tester.tap(find.byKey(_cancelKey));
        await _pumpFrames(tester);

        expect(capture.value, isFalse);
        expect(find.byKey(_dialogKey), findsNothing);
      });
    });

    group('ConfirmationIntent.destroy', () {
      testWidgets('renders localized common.discard label and destructive action variant', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(child: const _DialogHost(intent: ConfirmationIntent.destroy)),
        );
        await tester.pump();

        await tester.tap(find.byKey(_openKey));
        await _pumpFrames(tester);

        final translations = tester.element(find.byType(_DialogHost)).t;
        expect(find.byKey(_dialogKey), findsOneWidget);
        expect(find.text(translations.common.cancel), findsOneWidget);
        expect(find.text(translations.common.discard), findsOneWidget);

        // The destructive action button uses the destructive variant.
        final action = tester.widget<FButton>(find.byKey(_actionKey));
        expect(action.variant, FButtonVariant.destructive);
        // The cancel/keep button stays outline.
        final cancel = tester.widget<FButton>(find.byKey(_cancelKey));
        expect(cancel.variant, FButtonVariant.outline);
      });

      testWidgets('destroy action returns true', (tester) async {
        final capture = _ResultCapture();
        await tester.pumpWidget(
          _harness(
            child: _DialogHost(intent: ConfirmationIntent.destroy, onResult: capture.record),
          ),
        );
        await tester.pump();

        await tester.tap(find.byKey(_openKey));
        await _pumpFrames(tester);

        await tester.tap(find.byKey(_actionKey));
        await _pumpFrames(tester);

        expect(capture.value, isTrue);
      });
    });

    testWidgets('confirm-intent action button uses the primary variant', (tester) async {
      await tester.pumpWidget(
        _harness(child: const _DialogHost(intent: ConfirmationIntent.confirm)),
      );
      await tester.pump();

      await tester.tap(find.byKey(_openKey));
      await _pumpFrames(tester);

      final action = tester.widget<FButton>(find.byKey(_actionKey));
      expect(action.variant, FButtonVariant.primary);
      final cancel = tester.widget<FButton>(find.byKey(_cancelKey));
      expect(cancel.variant, FButtonVariant.outline);
    });

    testWidgets('custom labels override the localized defaults', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const _DialogHost(
            intent: ConfirmationIntent.confirm,
            confirmLabel: 'Delete it',
            cancelLabel: 'Keep it',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_openKey));
      await _pumpFrames(tester);

      expect(find.text('Delete it'), findsOneWidget);
      expect(find.text('Keep it'), findsOneWidget);
    });

    testWidgets('wraps in EscapeDismissibleOverlay', (tester) async {
      await tester.pumpWidget(
        _harness(child: const _DialogHost(intent: ConfirmationIntent.confirm)),
      );
      await tester.pump();

      await tester.tap(find.byKey(_openKey));
      await _pumpFrames(tester);

      expect(find.byType(EscapeDismissibleOverlay), findsOneWidget);
    });

    testWidgets('Escape dismisses with null result (no confirm)', (tester) async {
      final capture = _ResultCapture();
      await tester.pumpWidget(
        _harness(
          child: _DialogHost(intent: ConfirmationIntent.confirm, onResult: capture.record),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_openKey));
      await _pumpFrames(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _pumpFrames(tester);

      // The future resolved exactly once with `null` — Escape is a dismiss,
      // not a confirm (audit #5: maybePop completes regardless of animation).
      expect(capture.callCount, 1);
      expect(capture.value, isNull);
      expect(find.byKey(_dialogKey), findsNothing);
    });

    testWidgets('reduce-motion: confirm still completes', (tester) async {
      final capture = _ResultCapture();
      await tester.pumpWidget(
        _harness(
          reduceMotion: true,
          child: _DialogHost(intent: ConfirmationIntent.confirm, onResult: capture.record),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_openKey));
      await _pumpFrames(tester);

      await tester.tap(find.byKey(_actionKey));
      await _pumpFrames(tester);

      expect(capture.value, isTrue);
      expect(find.byKey(_dialogKey), findsNothing);
    });
  });
}

/// Mutable recorder for the dialog result + how many times the listener fired.
///
/// Wrapping the `bool?` in a small class dodges `avoid_positional_boolean_parameters`
/// on the listener typedef while keeping the call sites readable.
class _ResultCapture {
  bool? value;
  int callCount = 0;

  void record({bool? result}) {
    value = result;
    callCount += 1;
  }
}

class _DialogHost extends StatelessWidget {
  const _DialogHost({
    required this.intent,
    this.confirmLabel,
    this.cancelLabel,
    this.onResult,
  });

  final ConfirmationIntent intent;
  final String? confirmLabel;
  final String? cancelLabel;
  final void Function({bool? result})? onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FButton(
          key: _openKey,
          onPress: () {
            unawaited(
              AppConfirmationDialog.show(
                context,
                intent: intent,
                title: 'Confirm Title',
                body: 'Confirm Body',
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
              ).then((value) => onResult?.call(result: value)),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required Widget child, bool reduceMotion = false}) {
  return TranslationProvider(
    child: Builder(
      builder: (context) {
        final localeData = TranslationProvider.of(context);
        final theme = generated.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeData.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          home: child,
          builder: (context, built) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: FTheme(
              data: theme,
              child: FToaster(
                child: FTooltipGroup(child: built ?? const SizedBox.shrink()),
              ),
            ),
          ),
        );
      },
    ),
  );
}
