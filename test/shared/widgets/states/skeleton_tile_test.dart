import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/states/skeleton_tile.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('SkeletonTile', () {
    testWidgets('renders an FCard mirroring a tile layout', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(child: SkeletonTile()),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(SkeletonTile), findsOneWidget);
      expect(find.byType(FCard), findsOneWidget);
      // Leading avatar + title line + subtitle line.
      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonLine), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('omits the subtitle line when includeSubtitle is false', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(
            child: SkeletonTile(includeSubtitle: false),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(SkeletonLine), findsOneWidget);
    });

    testWidgets('measurable under reduce-motion with no shimmer ticker', (tester) async {
      await tester.pumpWidget(
        _harness(
          reduceMotion: true,
          child: const SkeletonView(child: SkeletonTile()),
        ),
      );
      await _pumpFrames(tester);

      expect(tester.hasRunningAnimations, isFalse);
      final cardSize = tester.getSize(find.byType(FCard));
      expect(cardSize.width, greaterThan(0));
      expect(cardSize.height, greaterThan(0));
    });
  });

  group('SkeletonCard', () {
    testWidgets('renders a card with an icon box, title, and body lines', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(child: SkeletonCard(lineCount: 3)),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(FCard), findsOneWidget);
      // 1 icon box + 1 title line + 3 body lines, each line renders a box.
      expect(find.byType(SkeletonLine), findsNWidgets(4));
      expect(find.byType(SkeletonBox), findsNWidgets(5));
    });

    testWidgets('renders under RTL without errors', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(
            child: Column(
              children: <Widget>[
                SkeletonTile(),
                SkeletonCard(),
              ],
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(SkeletonTile), findsOneWidget);
      expect(find.byType(SkeletonCard), findsOneWidget);
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
