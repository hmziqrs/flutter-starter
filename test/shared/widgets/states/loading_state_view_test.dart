import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/busy_indicator.dart';
import 'package:starter/shared/widgets/states/loading_state_view.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('LoadingStateView', () {
    testWidgets('renders the caption and reuses the BusyIndicator primitive', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const LoadingStateView(title: 'Loading…'),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(FCard), findsOneWidget);
      expect(find.byType(BusyIndicator), findsOneWidget);
      expect(find.byType(FCircularProgress), findsOneWidget);
      expect(find.text('Loading…'), findsOneWidget);
    });

    testWidgets('renders a determinate bar when a value is supplied', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const LoadingStateView(title: 'Loading…', value: 0.6),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(BusyIndicator), findsOneWidget);
      expect(find.byType(FDeterminateProgress), findsOneWidget);
      expect(
        tester.widget<FDeterminateProgress>(find.byType(FDeterminateProgress)).value,
        0.6,
      );
    });

    testWidgets('forwards an explicit semanticsLabel to the spinner', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const LoadingStateView(title: 'Loading…', semanticsLabel: 'Fetching activity'),
        ),
      );
      await _pumpFrames(tester);

      expect(
        tester.widget<FCircularProgress>(find.byType(FCircularProgress)).semanticsLabel,
        'Fetching activity',
      );
    });

    testWidgets('defaults the spinner semanticsLabel to the title', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const LoadingStateView(title: 'Loading…'),
        ),
      );
      await _pumpFrames(tester);

      expect(
        tester.widget<FCircularProgress>(find.byType(FCircularProgress)).semanticsLabel,
        'Loading…',
      );
    });

    testWidgets('reduce-motion omits the spinner and shows the static caption', (tester) async {
      await tester.pumpWidget(
        _harness(
          reduceMotion: true,
          child: const LoadingStateView(title: 'Loading…'),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('loading-state-view')), findsOneWidget);
      expect(find.byType(BusyIndicator), findsNothing);
      expect(find.byType(FCircularProgress), findsNothing);
      expect(find.text('Loading…'), findsOneWidget);
    });

    testWidgets('renders localized ar caption under RTL without errors', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => LoadingStateView(title: context.t.states.loadingTitle),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(FCard), findsOneWidget);
      expect(
        find.text(LocaleSettings.instance.getTranslations(AppLocale.ar).states.loadingTitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
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
        final locale = TranslationProvider.of(context);
        final theme = generated.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          home: Scaffold(body: Center(child: child)),
          builder: (context, built) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: Directionality(
              textDirection: locale.locale == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr,
              child: FTheme(
                data: theme,
                child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
              ),
            ),
          ),
        );
      },
    ),
  );
}
