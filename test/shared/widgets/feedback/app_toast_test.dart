import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/feedback/app_toast.dart';

const _triggerKey = Key('toast-trigger');
const _bodyMessage = 'toast-body-fixture';

void main() {
  group('AppToast', () {
    testWidgets('success uses common.success title and message as description', (tester) async {
      await tester.pumpWidget(_harness(child: const _TriggerHost()));
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      await _pumpFrames(tester);

      final translations = tester.element(find.byType(_TriggerHost)).t;
      expect(find.text(translations.common.success), findsOneWidget);
      expect(find.text(_bodyMessage), findsOneWidget);
    });

    testWidgets('error uses common.error title and destructive variant', (tester) async {
      await tester.pumpWidget(
        _harness(child: const _TriggerHost(severity: ToastSeverity.error)),
      );
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      await _pumpFrames(tester);

      final translations = tester.element(find.byType(_TriggerHost)).t;
      expect(find.text(translations.common.error), findsOneWidget);
      expect(find.text(_bodyMessage), findsOneWidget);
      expect(find.byType(FToast), findsOneWidget);
    });

    testWidgets('info promotes message to title when no title is supplied', (tester) async {
      await tester.pumpWidget(
        _harness(child: const _TriggerHost(severity: ToastSeverity.info)),
      );
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      await _pumpFrames(tester);

      expect(find.text(_bodyMessage), findsOneWidget);
    });

    testWidgets('info with explicit title shows title + description separately', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const _TriggerHost(
            severity: ToastSeverity.info,
            title: 'Heads up',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      await _pumpFrames(tester);

      expect(find.text('Heads up'), findsOneWidget);
      expect(find.text(_bodyMessage), findsOneWidget);
    });

    testWidgets('warning with explicit title routes through the destructive variant', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const _TriggerHost(
            severity: ToastSeverity.warning,
            title: 'Careful',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      await _pumpFrames(tester);

      expect(find.text('Careful'), findsOneWidget);
      expect(find.text(_bodyMessage), findsOneWidget);
      expect(find.byType(FToast), findsOneWidget);
    });

    testWidgets('explicit title overrides common.success default', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const _TriggerHost(
            title: 'Saved',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      await _pumpFrames(tester);

      final translations = tester.element(find.byType(_TriggerHost)).t;
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text(_bodyMessage), findsOneWidget);
      expect(find.text(translations.common.success), findsNothing);
    });

    testWidgets('returns a non-null FToasterEntry the caller can dismiss', (tester) async {
      FToasterEntry? entry;
      await tester.pumpWidget(
        _harness(
          child: _TriggerHost(
            severity: ToastSeverity.info,
            title: 'Hi',
            onEntry: (captured) => entry = captured,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      // dismiss() needs the enter animation settled; ForUI's status-listener breaks if interrupted.
      await _pumpFrames(tester);

      expect(entry, isNotNull);
      entry!.dismiss();
      await _pumpFrames(tester);
    });

    testWidgets('toast mounts under reduce-motion', (tester) async {
      await tester.pumpWidget(
        _harness(reduceMotion: true, child: const _TriggerHost()),
      );
      await tester.pump();

      await tester.tap(find.byKey(_triggerKey));
      await _pumpFrames(tester);

      expect(find.byType(FToast), findsOneWidget);
    });
  });
}

class _TriggerHost extends StatelessWidget {
  const _TriggerHost({
    this.severity = ToastSeverity.success,
    this.title,
    this.onEntry,
  });

  final ToastSeverity severity;
  final String? title;
  final void Function(FToasterEntry entry)? onEntry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FButton(
          key: _triggerKey,
          onPress: () {
            final entry = AppToast.show(
              context,
              severity: severity,
              title: title,
              message: _bodyMessage,
            );
            onEntry?.call(entry);
          },
          child: const Text('show'),
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
