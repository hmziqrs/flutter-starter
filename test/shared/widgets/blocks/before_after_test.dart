import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/before_after.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

void main() {
  group('AppBeforeAfter', () {
    testWidgets('draws one hairline row per comparison, struck before marked after', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppBeforeAfter(
            beforeLabel: 'By hand',
            afterLabel: 'With the kit',
            rows: <AppBeforeAfterRow>[
              AppBeforeAfterRow(
                what: 'Colors',
                before: 'Pick hexes per screen.',
                after: 'Resolve tokens from the theme.',
              ),
              AppBeforeAfterRow(
                what: 'Status',
                before: 'Restyle status chips everywhere.',
                after: 'Status roles stay soft everywhere.',
              ),
            ],
          ),
        ),
      );

      // One struck side and one marked side per row; the marker is the
      // filled primary ring, never a dot of another shape or color.
      expect(find.byType(AppRingMarker), findsNWidgets(2));
      expect(find.text('Pick hexes per screen.'), findsOneWidget);
      expect(find.text('Resolve tokens from the theme.'), findsOneWidget);
      expect(find.text('Colors'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);

      final light = generated.lightTheme;
      final struck = tester.widget<Text>(find.text('Pick hexes per screen.')).style!;
      expect(struck.decoration, TextDecoration.lineThrough);
      expect(struck.color, light.colors.mutedForeground);
      expect(
        tester.widget<Text>(find.text('Resolve tokens from the theme.')).style!.decoration,
        isNot(TextDecoration.lineThrough),
      );
    });

    testWidgets('rows carry hairlines on a muted border, not the foreground', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppBeforeAfter(
            rows: <AppBeforeAfterRow>[
              AppBeforeAfterRow(what: 'Colors', before: 'A', after: 'B'),
            ],
          ),
        ),
      );

      final light = generated.lightTheme;
      final hairlines = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(AppBeforeAfter),
              matching: find.byWidgetPredicate(
                (widget) => widget is Container && widget.decoration is BoxDecoration,
              ),
            ),
          )
          .where(
            (container) =>
                (container.decoration! as BoxDecoration).border?.top.style == BorderStyle.solid ||
                (container.decoration! as BoxDecoration).border?.bottom.style == BorderStyle.solid,
          )
          .toList();
      expect(hairlines.length, 2); // the list's opening line + the row's closing line
      for (final container in hairlines) {
        final border = container.decoration! as BoxDecoration;
        final top = border.border?.top;
        final side = top != null && top.style == BorderStyle.solid ? top : border.border!.bottom;
        expect(side.color, light.colors.border);
      }
    });

    testWidgets('the wide layout adds the 16rem what column and the arrow', (tester) async {
      tester.view
        ..physicalSize = const Size(1200, 800)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _harness(
          width: AppBeforeAfter.wideBreakpoint + 20,
          child: const AppBeforeAfter(
            rows: <AppBeforeAfterRow>[
              AppBeforeAfterRow(what: 'Colors', before: 'A', after: 'B'),
            ],
          ),
        ),
      );

      expect(find.byIcon(FLucideIcons.arrowRight), findsOneWidget);
      // The "what" lead-in owns the svelte's 16rem column from the wide grid.
      expect(
        find.byWidgetPredicate((widget) => widget is SizedBox && widget.width == 256),
        findsOneWidget,
      );
    });

    testWidgets('screen readers hear the before and after labels spelled out', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppBeforeAfter(
            beforeLabel: 'By hand',
            afterLabel: 'With the kit',
            rows: <AppBeforeAfterRow>[
              AppBeforeAfterRow(what: 'Colors', before: 'A', after: 'B'),
            ],
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'By hand: A',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'With the kit: B',
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _harness({required Widget child, double width = 400}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}
