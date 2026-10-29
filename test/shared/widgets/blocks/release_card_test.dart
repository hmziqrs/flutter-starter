import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/release_card.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';

AppReleaseCard _card() => const AppReleaseCard(
  version: '0.12.0',
  date: 'August 26, 2026',
  product: 'claude-multi',
  symbol: 'Cm',
  symbolLabel: 'claude-multi mark',
  latestLabel: 'Latest',
  groups: <AppReleaseGroup>[
    (
      kind: AppReleaseChangeKind.changed,
      lines: <String>['GLM template update: sonnet-tier now maps to glm-5.3-flash.'],
    ),
    (
      kind: AppReleaseChangeKind.fixed,
      lines: <String>[
        'Provider detection now accepts endpoints with a trailing slash.',
        'Doctor spots structural environment values that differ.',
      ],
    ),
  ],
  installs: <AppReleaseInstall>[
    (manager: 'bun', command: 'bun add -g claude-multi'),
    (manager: 'npm', command: 'npm install -g claude-multi'),
  ],
  notesLabel: 'All release notes',
);

void main() {
  group('AppReleaseCard', () {
    testWidgets('shows version over product, latest tag and date in the header', (tester) async {
      await tester.pumpWidget(_harness(tester, child: SizedBox(width: 480, child: _card())));

      final order = <double>[
        tester.getTopLeft(find.text('claude-multi')).dy,
        tester.getTopLeft(find.text('0.12.0')).dy,
      ];
      expect(order[0], lessThan(order[1]));
      // The latest tag and the date share the header's end column.
      expect(
        tester.getTopLeft(find.text('Latest')).dy,
        lessThan(tester.getTopLeft(find.text('August 26, 2026')).dy),
      );
    });

    testWidgets('runs the version large in mono', (tester) async {
      await tester.pumpWidget(_harness(tester, child: SizedBox(width: 480, child: _card())));

      final version = tester.widget<Text>(find.text('0.12.0')).style!;
      expect(version.fontFamily, 'JetBrains Mono');
      expect(version.fontSize, 30);
      expect(version.fontWeight, FontWeight.w500);
      expect(version.letterSpacing, closeTo(-0.025 * 30, 0.001));
    });

    testWidgets('carries the latest release in a material tag', (tester) async {
      await tester.pumpWidget(_harness(tester, child: SizedBox(width: 480, child: _card())));

      // The material-edged pill hugs its label in the header's end column,
      // above the date.
      final tag = find.byWidgetPredicate(
        (widget) =>
            widget is ClipRRect &&
            widget.borderRadius == const BorderRadius.all(Radius.circular(11.5)),
      );
      expect(tag, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Latest')).dy,
        lessThan(tester.getTopLeft(find.text('August 26, 2026')).dy),
      );
    });

    testWidgets('kind tags count their group in the kind color role', (tester) async {
      await tester.pumpWidget(_harness(tester, child: SizedBox(width: 480, child: _card())));

      final changed = tester.widget<AppStatusTag>(find.widgetWithText(AppStatusTag, 'Changed 1'));
      expect(changed.role, AppStatusRole.info);
      final fixed = tester.widget<AppStatusTag>(find.widgetWithText(AppStatusTag, 'Fixed 2'));
      expect(fixed.role, AppStatusRole.warning);
    });

    testWidgets('counts the lines past the visible two', (tester) async {
      await tester.pumpWidget(
        _harness(
          tester,
          child: const SizedBox(
            width: 480,
            child: AppReleaseCard(
              version: '0.11.1',
              date: 'August 22, 2026',
              groups: <AppReleaseGroup>[
                (
                  kind: AppReleaseChangeKind.fixed,
                  lines: <String>['one', 'two', 'three', 'four'],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('and 2 more'), findsOneWidget);
      expect(find.text('three'), findsNothing);
    });

    testWidgets('picks the install command through the segmented manager', (tester) async {
      await tester.pumpWidget(_harness(tester, child: SizedBox(width: 480, child: _card())));

      expect(find.text('bun add -g claude-multi'), findsOneWidget);
      await tester.tap(find.text('npm'));
      await tester.pump();
      expect(find.text('npm install -g claude-multi'), findsOneWidget);
    });

    testWidgets('reads the notes link after an arrow', (tester) async {
      await tester.pumpWidget(_harness(tester, child: SizedBox(width: 480, child: _card())));

      final notes = tester.getCenter(find.text('All release notes'));
      final arrow = tester.getCenter(find.byIcon(FLucideIcons.arrowRight));
      expect(arrow.dx, greaterThan(notes.dx));
    });
  });
}

Widget _harness(WidgetTester tester, {required Widget child}) {
  // The generated test theme runs touch typography (16dp body), so the
  // fixture's lines wrap taller than they ever would with the shipped fonts;
  // a 480x900 logical surface holds the whole card.
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(960, 1800);
  addTearDown(tester.view.reset);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
