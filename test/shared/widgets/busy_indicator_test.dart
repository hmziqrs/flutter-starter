import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/busy_indicator.dart';

void main() {
  group('BusyIndicator', () {
    testWidgets('none severity renders nothing', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator(severity: BusySeverity.none)),
      );

      expect(find.byType(BusyIndicator), findsOneWidget);
      expect(find.byType(FCircularProgress), findsNothing);
      expect(find.byType(FDeterminateProgress), findsNothing);
    });

    testWidgets('indeterminate value renders FCircularProgress', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator()),
      );

      expect(find.byType(FCircularProgress), findsOneWidget);
      expect(find.byType(FDeterminateProgress), findsNothing);
    });

    testWidgets('determinate value renders FDeterminateProgress at the given fraction', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator(value: 0.6)),
      );

      expect(find.byType(FDeterminateProgress), findsOneWidget);
      expect(find.byType(FCircularProgress), findsNothing);
      expect(
        tester.widget<FDeterminateProgress>(find.byType(FDeterminateProgress)).value,
        0.6,
      );
    });

    testWidgets('clamps determinate value above 1.0 to 1.0', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator(value: 1.5)),
      );

      expect(
        tester.widget<FDeterminateProgress>(find.byType(FDeterminateProgress)).value,
        1.0,
      );
    });

    testWidgets('clamps determinate value below 0.0 to 0.0', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator(value: -0.5)),
      );

      expect(
        tester.widget<FDeterminateProgress>(find.byType(FDeterminateProgress)).value,
        0.0,
      );
    });

    testWidgets('forwards an explicit semanticsLabel to the primitive', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator(semanticsLabel: 'Working')),
      );

      expect(
        tester.widget<FCircularProgress>(find.byType(FCircularProgress)).semanticsLabel,
        'Working',
      );
    });

    testWidgets('saving severity defaults the semanticsLabel to common.saving', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator(severity: BusySeverity.saving)),
      );

      expect(
        tester.widget<FCircularProgress>(find.byType(FCircularProgress)).semanticsLabel,
        'Saving…',
      );
    });

    testWidgets('active severity defaults the semanticsLabel to common.loading', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BusyIndicator()),
      );

      expect(
        tester.widget<FCircularProgress>(find.byType(FCircularProgress)).semanticsLabel,
        'Loading',
      );
    });
  });
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
          home: Scaffold(body: Center(child: child)),
          builder: (context, built) => FTheme(
            data: theme,
            child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
          ),
        );
      },
    ),
  );
}
