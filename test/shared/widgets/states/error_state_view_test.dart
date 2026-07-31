import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/states/error_state_view.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('ErrorStateView', () {
    testWidgets('renders the title and body inside an FCard without an action', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const ErrorStateView(title: 'Could not load this', body: 'Something went wrong.'),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(FCard), findsOneWidget);
      expect(find.text('Could not load this'), findsOneWidget);
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.byType(FButton), findsNothing);
    });

    testWidgets('renders the retry affordance and fires the feature-supplied callback', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        _harness(
          child: ErrorStateView(
            title: 'Could not load this',
            body: 'Something went wrong.',
            action: (label: 'Retry', onTap: () => retries += 1),
          ),
        ),
      );
      await _pumpFrames(tester);

      final button = find.byKey(const ValueKey('error-state-view-action'));
      expect(button, findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(button);
      await _pumpFrames(tester);
      expect(retries, 1);
    });

    testWidgets('uses the default circle-alert icon when none is supplied', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const ErrorStateView(title: 'Could not load this', body: 'Something went wrong.'),
        ),
      );
      await _pumpFrames(tester);

      expect(tester.widget<Icon>(find.byType(Icon)).icon, FLucideIcons.circleAlert);
    });

    testWidgets('honors an explicit override icon', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const ErrorStateView(
            title: 'Could not load this',
            body: 'Something went wrong.',
            icon: FLucideIcons.triangleAlert,
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(tester.widget<Icon>(find.byType(Icon)).icon, FLucideIcons.triangleAlert);
    });

    testWidgets('renders localized ar strings under RTL without errors', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => ErrorStateView(
              title: context.t.states.errorTitle,
              body: context.t.states.errorBody,
              action: (label: context.t.common.retry, onTap: () {}),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(FCard), findsOneWidget);
      expect(
        find.text(LocaleSettings.instance.getTranslations(AppLocale.ar).states.errorTitle),
        findsOneWidget,
      );
      expect(
        find.text(LocaleSettings.instance.getTranslations(AppLocale.ar).common.retry),
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

Widget _harness({required Widget child}) {
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
          builder: (context, built) => Directionality(
            textDirection: locale.locale == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr,
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
