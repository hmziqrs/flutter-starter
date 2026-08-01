import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_presentation_state.dart';
import 'package:starter/features/feedback/feedback_sheet.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/feedback/in_memory_feedback_transport.dart';
import 'package:starter/features/feedback/noop_feedback_transport.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

const _metadata = FeedbackAppMetadata(
  appVersion: '1.0.0+1',
  platform: 'ios',
  locale: 'en',
);

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('FeedbackSheetBody', () {
    testWidgets('renders title, message field, screenshot toggle, submit + cancel', (tester) async {
      await tester.pumpWidget(
        _harness(
          transport: const NoopFeedbackTransport(),
          child: const FeedbackSheetBody(
            onDismiss: _noop,
            onAccepted: _noop,
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text(t.feedback.title), findsOneWidget);
      expect(find.text(t.feedback.messageLabel), findsOneWidget);
      expect(find.text(t.feedback.includeScreenshot), findsOneWidget);
      expect(find.text(t.feedback.submit), findsOneWidget);
      expect(find.text(t.feedback.cancel), findsOneWidget);
    });

    testWidgets('Noop transport submit surfaces failed + notConnected, never success', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          transport: const NoopFeedbackTransport(),
          child: const FeedbackSheetBody(
            onDismiss: _noop,
            onAccepted: _noop,
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(find.byKey(const ValueKey('feedback-message')), 'a real report');
      await _pumpFrames(tester);

      await tester.tap(find.text(t.feedback.submit));
      await _pumpFrames(tester);

      expect(find.text(t.common.notConnected), findsOneWidget);
      expect(find.text(t.feedback.successTitle), findsNothing);
    });

    testWidgets('accepted transport flips to success copy', (tester) async {
      var accepted = false;
      await tester.pumpWidget(
        _harness(
          transport: InMemoryFeedbackTransport(),
          child: FeedbackSheetBody(
            onDismiss: _noop,
            onAccepted: () => accepted = true,
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(find.byKey(const ValueKey('feedback-message')), 'hello');
      await _pumpFrames(tester);

      await tester.tap(find.text(t.feedback.submit));
      await _pumpFrames(tester);

      expect(find.text(t.feedback.successTitle), findsOneWidget);
      expect(find.text(t.feedback.successBody), findsOneWidget);
      expect(accepted, isTrue);
    });

    testWidgets('empty message keeps submit disabled at the form-validator level', (tester) async {
      await tester.pumpWidget(
        _harness(
          transport: InMemoryFeedbackTransport(),
          child: const FeedbackSheetBody(
            onDismiss: _noop,
            onAccepted: _noop,
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.text(t.feedback.submit));
      await _pumpFrames(tester);

      expect(find.text(t.feedback.successTitle), findsNothing);
      final transport = _transportOf(tester);
      expect(transport.submissions, isEmpty);
    });

    testWidgets('Cancel button dismisses without submitting (no transport round-trip)', (
      tester,
    ) async {
      var dismissed = false;
      await tester.pumpWidget(
        _harness(
          transport: InMemoryFeedbackTransport(),
          child: FeedbackSheetBody(
            onDismiss: () => dismissed = true,
            onAccepted: _noop,
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.enterText(find.byKey(const ValueKey('feedback-message')), 'draft');
      await _pumpFrames(tester);

      await tester.tap(find.text(t.feedback.cancel));
      await _pumpFrames(tester);

      expect(dismissed, isTrue);
      expect(_transportOf(tester).submissions, isEmpty);
    });

    testWidgets('screenshot toggle is reachable and flips intent', (tester) async {
      await tester.pumpWidget(
        _harness(
          transport: const NoopFeedbackTransport(),
          child: const FeedbackSheetBody(
            onDismiss: _noop,
            onAccepted: _noop,
          ),
        ),
      );
      await _pumpFrames(tester);

      final toggle = find.byKey(const ValueKey('feedback-include-screenshot'));
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await _pumpFrames(tester);

      final fsSwitch = tester.widget<FSwitch>(toggle);
      expect(fswitchValue(fsSwitch), isTrue);
    });

    testWidgets('fixture presentation renders failed alert without a controller', (tester) async {
      await tester.pumpWidget(
        _harness(
          transport: const NoopFeedbackTransport(),
          child: const FeedbackSheetBody(
            presentation: FeedbackPresentationState.failed(),
            onDismiss: _noop,
            onAccepted: _noop,
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text(t.common.notConnected), findsOneWidget);
      expect(find.text(t.feedback.failedTitle), findsOneWidget);
    });

    testWidgets('fixture presentation renders success copy', (tester) async {
      await tester.pumpWidget(
        _harness(
          transport: const NoopFeedbackTransport(),
          child: const FeedbackSheetBody(
            presentation: FeedbackPresentationState.success(),
            onDismiss: _noop,
            onAccepted: _noop,
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text(t.feedback.successTitle), findsOneWidget);
      expect(find.text(t.feedback.successBody), findsOneWidget);
    });
  });

  group('FeedbackTriageState / FeedbackOutcome', () {
    test('outcomes cover accepted / rejected / unavailable', () {
      expect(FeedbackOutcome.values, contains(FeedbackOutcome.accepted));
      expect(FeedbackOutcome.values, contains(FeedbackOutcome.rejected));
      expect(FeedbackOutcome.values, contains(FeedbackOutcome.unavailable));
    });

    test('accepted result carries an id; others do not', () {
      expect(const FeedbackResult.accepted('abc').id, 'abc');
      expect(const FeedbackResult.unavailable().id, isNull);
      expect(const FeedbackResult.rejected().id, isNull);
    });
  });
}

void _noop() {}

InMemoryFeedbackTransport _transportOf(WidgetTester tester) {
  final scope = ProviderScope.containerOf(
    tester.element(find.byType(FeedbackSheetBody)),
  );
  return scope.read(feedbackTransportProvider) as InMemoryFeedbackTransport;
}

bool fswitchValue(FSwitch widget) {
  return widget.value;
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({
  required FeedbackTransport transport,
  required Widget child,
  SettingsStore? store,
}) {
  final settingsStore = store ?? InMemorySettingsStore();
  return ProviderScope(
    overrides: [
      feedbackTransportProvider.overrideWithValue(transport),
      settingsStoreProvider.overrideWithValue(settingsStore),
      initialFeedbackDraftProvider.overrideWithValue(const FeedbackDraft.empty()),
      initialFeedbackShakeEnabledProvider.overrideWithValue(false),
      feedbackAppMetadataProvider.overrideWithValue(_metadata),
    ],
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            home: Scaffold(body: SingleChildScrollView(child: child)),
            builder: (context, built) => FTheme(
              data: theme,
              child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
            ),
          );
        },
      ),
    ),
  );
}
