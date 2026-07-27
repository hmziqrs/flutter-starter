import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/states/skeleton_view.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('SkeletonStyle', () {
    testWidgets('of(context) derives base/highlight colors from the theme', (tester) async {
      SkeletonStyle? captured;
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) {
              captured = SkeletonStyle.of(context);
              return const SkeletonBox(width: 100, height: 12);
            },
          ),
        ),
      );
      await _pumpFrames(tester);

      final colors = generated.lightTheme.colors;
      final expectedBase = Color.lerp(colors.background, colors.foreground, 0.10)!;
      final expectedHighlight = Color.lerp(expectedBase, const Color(0xFFFFFFFF), 0.35)!;
      expect(captured!.baseColor, expectedBase);
      expect(captured!.highlightColor, expectedHighlight);
      // Highlight is perceptually lighter than the base.
      expect(
        _luminance(captured!.highlightColor),
        greaterThan(_luminance(captured!.baseColor)),
      );
    });

    testWidgets('has value equality', (tester) async {
      await tester.pumpWidget(_harness(child: const SizedBox.shrink()));
      await _pumpFrames(tester);
      const a = SkeletonStyle(baseColor: Color(0xFF111111), highlightColor: Color(0xFF222222));
      const b = SkeletonStyle(baseColor: Color(0xFF111111), highlightColor: Color(0xFF222222));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('SkeletonView', () {
    testWidgets('renders the mirrored subtree of bones', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(
            child: Column(
              children: <Widget>[
                SkeletonBox(width: 120, height: 12),
                SkeletonLine(widthFraction: 0.6, height: 10),
                SkeletonCircle(size: 28),
              ],
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(SkeletonView), findsOneWidget);
      // 1 direct box + 1 from the line + 1 from the circle = 3 bone boxes.
      expect(find.byType(SkeletonBox), findsNWidgets(3));
      expect(find.byType(SkeletonLine), findsOneWidget);
      expect(find.byType(SkeletonCircle), findsOneWidget);
      // Bones are measurable: the fixed-size box has the requested geometry.
      final box = tester.getSize(find.byType(SkeletonBox).first);
      expect(box.width, 120);
      expect(box.height, 12);
    });

    testWidgets('animated path drives a repeating shimmer ticker', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(child: SkeletonBox(width: 100, height: 12)),
        ),
      );
      // One frame to mount; the controller.repeat() ticker is now registered.
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('reduce-motion keeps the subtree measurable with no ticker', (tester) async {
      await tester.pumpWidget(
        _harness(
          reduceMotion: true,
          child: const SkeletonView(child: SkeletonBox(width: 100, height: 12)),
        ),
      );
      await _pumpFrames(tester);

      // Static fallback: no shimmer ticker.
      expect(tester.hasRunningAnimations, isFalse);
      // The subtree still lays out and is measurable.
      final box = tester.getSize(find.byType(SkeletonBox));
      expect(box.width, 100);
      expect(box.height, 12);
    });

    testWidgets('reduce-motion paints a static (non-animated) bone', (tester) async {
      await tester.pumpWidget(
        _harness(
          reduceMotion: true,
          child: const SkeletonView(
            child: SkeletonBox(key: ValueKey('bone'), width: 80, height: 16),
          ),
        ),
      );
      await _pumpFrames(tester);

      // Static fallback: the bone's CustomPaint has a painter but no ticker is
      // driving it (the painter's repaint listenable is null under reduce-motion).
      expect(find.byType(CustomPaint), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('forwards semanticsLabel defaulting to states.loadingTitle', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(child: SkeletonBox(width: 50, height: 8)),
        ),
      );
      await _pumpFrames(tester);

      final expected = LocaleSettings.instance.getTranslations(AppLocale.en).states.loadingTitle;
      expect(
        find.bySemanticsLabel(expected),
        findsOneWidget,
      );
    });

    testWidgets('respects an explicit semanticsLabel', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(
            semanticsLabel: 'Fetching recent activity',
            child: SkeletonBox(width: 50, height: 8),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.bySemanticsLabel('Fetching recent activity'), findsOneWidget);
    });

    testWidgets('renders under RTL without errors', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await tester.pumpWidget(
        _harness(
          child: const SkeletonView(
            child: Column(
              children: <Widget>[
                SkeletonLine(widthFraction: 0.7),
                SkeletonCircle(size: 24),
              ],
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(SkeletonView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SkeletonLine', () {
    testWidgets('honors a fixed width over the fraction', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SkeletonLine(fixedWidth: 64, height: 10),
        ),
      );
      await _pumpFrames(tester);

      // SkeletonLine with fixedWidth renders one SkeletonBox of that width.
      final box = tester.getSize(find.byType(SkeletonBox));
      expect(box.width, 64);
      expect(box.height, 10);
    });

    testWidgets('clamps an out-of-range fraction without asserting', (tester) async {
      await tester.pumpWidget(
        _harness(child: const SkeletonLine(widthFraction: 5)),
      );
      await _pumpFrames(tester);
      expect(tester.takeException(), isNull);
      // The fractional box never overflows the harness content width.
      final viewport = tester.getSize(find.byType(SkeletonLine));
      expect(viewport.width, lessThanOrEqualTo(800));
    });
  });
}

double _luminance(Color c) => c.computeLuminance();

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
