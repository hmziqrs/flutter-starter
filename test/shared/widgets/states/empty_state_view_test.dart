import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/states/empty_state_view.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('EmptyStateView', () {
    testWidgets('renders the unboxed column without an action', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const EmptyStateView(title: 'Nothing here yet', body: 'Content will appear here.'),
        ),
      );
      await _pumpFrames(tester);

      // APP-BLOCKS DataState: "No box" — the state is a centered column,
      // not a card.
      expect(find.byType(FCard), findsNothing);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('Content will appear here.'), findsOneWidget);
      expect(find.byType(FButton), findsNothing);
    });

    testWidgets('centers the column in the bounded content area', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(
            width: 400,
            height: 400,
            child: EmptyStateView(title: 'Nothing here yet', body: 'Content will appear.'),
          ),
        ),
      );
      await _pumpFrames(tester);

      // empty-state.svelte's `flex-1 items-center justify-center`: the whole
      // column (tile, copy, padding) rides the middle of the content area
      // (y 100..500 in the 400x400 box), not the top of a card.
      final paddedColumn = find.byWidgetPredicate(
        (widget) => widget is Padding && widget.padding == const EdgeInsets.symmetric(vertical: 64),
      );
      expect(tester.getCenter(paddedColumn).dy, closeTo(300, 1));
    });

    testWidgets('renders the first-use action as the primary button and fires it', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          child: EmptyStateView(
            title: 'Nothing here yet',
            body: 'Content will appear here.',
            action: (label: 'Invite people', onTap: () => taps += 1),
          ),
        ),
      );
      await _pumpFrames(tester);

      final button = find.byKey(const ValueKey('empty-state-view-action'));
      expect(button, findsOneWidget);
      // APP-BLOCKS EmptyState: "for a first run, the one action that starts
      // things" — the states table's Primary, not an outline button.
      expect(tester.widget<FButton>(button).variant, FButtonVariant.primary);
      expect(find.text('Invite people'), findsOneWidget);

      await tester.tap(button);
      await _pumpFrames(tester);
      expect(taps, 1);
    });

    testWidgets('uses the default inbox icon when none is supplied', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const EmptyStateView(title: 'Nothing here yet', body: 'Content will appear here.'),
        ),
      );
      await _pumpFrames(tester);

      expect(tester.widget<Icon>(find.byType(Icon)).icon, FLucideIcons.inbox);
    });

    testWidgets('keeps the brand default primary icon on the outline tile', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const EmptyStateView(title: 'Nothing here yet', body: 'Content will appear here.'),
        ),
      );
      await _pumpFrames(tester);

      // empty-state.svelte renders a tone-less IconTile: the icon stays in
      // primary, never muted.
      expect(tester.widget<Icon>(find.byType(Icon)).color, generated.lightTheme.colors.primary);
    });

    testWidgets('honors an explicit override icon', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const EmptyStateView(
            title: 'Nothing here yet',
            body: 'Content will appear here.',
            icon: FLucideIcons.search,
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(tester.widget<Icon>(find.byType(Icon)).icon, FLucideIcons.search);
    });

    testWidgets('scrolls instead of overflowing in a short bounded region', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 320,
            height: 120,
            child: EmptyStateView(
              title: 'Nothing here yet',
              body: 'Content will appear here.',
              action: (label: 'Retry', onTap: () {}),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders localized ar strings under RTL without errors', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => EmptyStateView(
              title: context.t.states.emptyTitle,
              body: context.t.states.emptyBody,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(FCard), findsNothing);
      expect(
        find.text(LocaleSettings.instance.getTranslations(AppLocale.ar).states.emptyTitle),
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
