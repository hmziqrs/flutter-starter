import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/busy_indicator.dart';
import 'package:starter/shared/widgets/forms/form_scaffold.dart';

const _submitKey = ValueKey<String>('form-scaffold-submit');
const _barrierKey = ValueKey<String>('busy-overlay-barrier');

void main() {
  group('FormScaffold', () {
    testWidgets('disables the submit button until the form is valid', (
      tester,
    ) async {
      var submitted = 0;
      await tester.pumpWidget(
        _harness(
          child: FormScaffold(
            formKey: GlobalKey<FormState>(),
            isValid: false,
            onSubmit: () {
              submitted += 1;
            },
            submitLabel: 'Save',
            fields: const Text('email field'),
          ),
        ),
      );

      await tester.tap(find.byKey(_submitKey), warnIfMissed: false);
      // ForUI's FTappable schedules a short press timer on tap; pump bounded
      // frames (never pumpAndSettle) so it flushes before the test ends.
      await _pumpFrames(tester);

      expect(submitted, 0);
    });

    testWidgets('enables and invokes submit when the form is valid', (
      tester,
    ) async {
      var submitted = 0;
      await tester.pumpWidget(
        _harness(
          child: FormScaffold(
            formKey: GlobalKey<FormState>(),
            isValid: true,
            onSubmit: () {
              submitted += 1;
            },
            submitLabel: 'Save',
            fields: const Text('email field'),
          ),
        ),
      );

      await tester.tap(find.byKey(_submitKey));
      await _pumpFrames(tester);

      expect(submitted, 1);
    });

    testWidgets('mounts the busy overlay and spinner while submitting', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: FormScaffold(
            formKey: GlobalKey<FormState>(),
            isValid: true,
            isSubmitting: true,
            busyLabel: 'Saving',
            onSubmit: () async {},
            submitLabel: 'Save',
            fields: const Text('email field'),
          ),
        ),
      );

      expect(find.byKey(_barrierKey), findsOneWidget);
      expect(find.byType(BusyIndicator), findsOneWidget);
      expect(find.text('Saving'), findsOneWidget);
    });

    testWidgets('does not invoke submit while submitting', (tester) async {
      var submitted = 0;
      await tester.pumpWidget(
        _harness(
          child: FormScaffold(
            formKey: GlobalKey<FormState>(),
            isValid: true,
            isSubmitting: true,
            onSubmit: () => submitted += 1,
            submitLabel: 'Save',
            fields: const Text('email field'),
          ),
        ),
      );

      // The barrier absorbs the tap; the underlying submit does not fire.
      await tester.tap(find.byKey(_submitKey), warnIfMissed: false);
      await tester.pump();

      expect(submitted, 0);
    });

    testWidgets('renders heading and subheading when provided', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: FormScaffold(
            formKey: GlobalKey<FormState>(),
            isValid: true,
            onSubmit: () async {},
            submitLabel: 'Save',
            heading: const Text('Billing details'),
            subheading: const Text('Update your plan'),
            fields: const Text('email field'),
          ),
        ),
      );

      expect(find.text('Billing details'), findsOneWidget);
      expect(find.text('Update your plan'), findsOneWidget);
    });

    testWidgets('groups fields in an FCard by default', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: FormScaffold(
            formKey: GlobalKey<FormState>(),
            isValid: true,
            onSubmit: () async {},
            submitLabel: 'Save',
            fields: const Text('email field'),
          ),
        ),
      );

      expect(find.byType(FCard), findsOneWidget);
    });

    testWidgets('omits the FCard when groupInCard is false', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: FormScaffold(
            formKey: GlobalKey<FormState>(),
            isValid: true,
            groupInCard: false,
            onSubmit: () async {},
            submitLabel: 'Save',
            fields: const Text('email field'),
          ),
        ),
      );

      expect(find.byType(FCard), findsNothing);
    });
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  // Bounded frame pump (mirrors the integration pumpAppFrames contract) so
  // ForUI's short press timer flushes without pumpAndSettle.
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required Widget child}) {
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
          home: Scaffold(body: child),
          builder: (context, built) => FTheme(
            data: theme,
            child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
          ),
        );
      },
    ),
  );
}
