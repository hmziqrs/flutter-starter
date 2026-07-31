import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/busy_indicator.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

const _barrierKey = ValueKey<String>('busy-overlay-barrier');
const _submitKey = ValueKey<String>('busy-overlay-submit');

void main() {
  group('BusyOverlay', () {
    testWidgets('renders only the child while not busy', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const _Box(
            child: BusyOverlay(isBusy: false, child: Text('form')),
          ),
        ),
      );

      expect(find.text('form'), findsOneWidget);
      expect(find.byKey(_barrierKey), findsNothing);
      expect(find.byType(FCircularProgress), findsNothing);
    });

    testWidgets('mounts the scrim and spinner while busy', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const _Box(
            child: BusyOverlay(isBusy: true, child: Text('form')),
          ),
        ),
      );

      expect(find.byKey(_barrierKey), findsOneWidget);
      expect(find.byType(FCircularProgress), findsOneWidget);
      expect(find.text('Saving…'), findsOneWidget);
    });

    testWidgets('uses an explicit label and indeterminate value', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const _Box(
            child: BusyOverlay(
              isBusy: true,
              label: 'Signing in',
              child: Text('form'),
            ),
          ),
        ),
      );

      expect(find.text('Signing in'), findsOneWidget);
      expect(find.byType(FCircularProgress), findsOneWidget);
      expect(find.byType(FDeterminateProgress), findsNothing);
    });

    testWidgets('renders the determinate bar when a value is supplied', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const _Box(
            child: BusyOverlay(
              isBusy: true,
              value: 0.6,
              child: Text('form'),
            ),
          ),
        ),
      );

      expect(find.byType(FDeterminateProgress), findsOneWidget);
      expect(
        tester.widget<FDeterminateProgress>(find.byType(FDeterminateProgress)).value,
        0.6,
      );
    });

    testWidgets('blocks the wrapped submit while busy', (tester) async {
      var submits = 0;
      await tester.pumpWidget(
        _harness(
          child: _Box(
            child: BusyOverlay(
              isBusy: true,
              child: GestureDetector(
                key: _submitKey,
                onTap: () => submits += 1,
                child: const Text('submit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(_submitKey), warnIfMissed: false);
      await tester.pump();
      expect(submits, 0);

      await tester.pumpWidget(
        _harness(
          child: _Box(
            child: BusyOverlay(
              isBusy: false,
              child: GestureDetector(
                key: _submitKey,
                onTap: () => submits += 1,
                child: const Text('submit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
      expect(submits, 1);
    });

    testWidgets('reduce-motion shows a static label and omits the spinner', (tester) async {
      await tester.pumpWidget(
        _harness(
          reduceMotion: true,
          child: const _Box(
            child: BusyOverlay(isBusy: true, child: Text('form')),
          ),
        ),
      );

      expect(find.byKey(_barrierKey), findsOneWidget);
      expect(find.byType(FCircularProgress), findsNothing);
      expect(find.byType(BusyIndicator), findsNothing);
      expect(find.text('Saving…'), findsOneWidget);
    });

    testWidgets('still completes the action while the overlay is mounted', (tester) async {
      await tester.pumpWidget(_harness(child: const _SubmitHost()));

      await tester.tap(find.byKey(_submitKey));
      await _pumpFrames(tester);

      expect(find.byKey(_barrierKey), findsNothing);
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('completes the action under reduce-motion', (tester) async {
      await tester.pumpWidget(
        _harness(reduceMotion: true, child: const _SubmitHost()),
      );

      await tester.tap(find.byKey(_submitKey));
      await _pumpFrames(tester);

      expect(find.text('done'), findsOneWidget);
    });
  });
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 240, height: 160, child: child);
  }
}

class _SubmitHost extends StatefulWidget {
  const _SubmitHost();

  @override
  State<_SubmitHost> createState() => _SubmitHostState();
}

class _SubmitHostState extends State<_SubmitHost> {
  bool _busy = false;
  bool _saved = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 160,
      child: BusyOverlay(
        isBusy: _busy,
        child: GestureDetector(
          key: _submitKey,
          onTap: _submit,
          child: Center(child: Text(_saved ? 'done' : 'form')),
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
          home: Scaffold(body: Center(child: child)),
          builder: (context, built) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: FTheme(
              data: theme,
              child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
            ),
          ),
        );
      },
    ),
  );
}
