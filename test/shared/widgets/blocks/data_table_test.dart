import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/data_table.dart';

void main() {
  group('AppDataTable', () {
    testWidgets('puts the accent column on a soft primary wash with a primary heading', (
      tester,
    ) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(_harness(child: _boxed));

      // The accent heading reads in the primary; the others stay muted.
      expect(_textColor(tester, 'Recommended'), light.colors.primary);
      expect(_textColor(tester, 'Plan'), light.colors.mutedForeground);
      expect(_textColor(tester, 'Price'), light.colors.mutedForeground);

      // The accent column's cells carry the ~7% primary wash.
      final washes = tester
          .widgetList<Container>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.color == light.colors.primary.withValues(alpha: 0.07),
            ),
          )
          .toList();
      expect(washes, hasLength(3), reason: 'header plus two body rows');
    });

    testWidgets('keeps first-column names in the text color, other cells muted', (tester) async {
      await tester.pumpWidget(_harness(child: _boxed));
      final light = generated.lightTheme;

      expect(_textColor(tester, 'Free'), light.colors.foreground);
      expect(_textColor(tester, r'$0'), light.colors.mutedForeground);
    });

    testWidgets('boxed style draws one rounded outline and a single header line', (tester) async {
      await tester.pumpWidget(_harness(child: _boxed));
      final light = generated.lightTheme;

      final outlines = tester
          .widgetList<Container>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is ShapeDecoration &&
                  (widget.decoration! as ShapeDecoration).shape is RoundedSuperellipseBorder &&
                  ((widget.decoration! as ShapeDecoration).shape as RoundedSuperellipseBorder)
                          .borderRadius ==
                      light.style.borderRadius.lg,
            ),
          )
          .toList();
      expect(outlines, hasLength(1), reason: 'one boxed frame, not a frame per row');
    });

    testWidgets('docs style draws a strong line under headings and thin lines between rows', (
      tester,
    ) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(_harness(child: _docs));

      final rows = tester.widget<Table>(find.byType(Table)).children;
      expect(rows, hasLength(3));

      final headerBorder = (rows.first.decoration! as BoxDecoration).border! as Border;
      expect(headerBorder.bottom.color, light.colors.foreground);
      expect(headerBorder.bottom.width, 1, reason: 'strong means full-strength foreground');

      // Body rows are separated by the Table's thin inside lines.
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.border!.horizontalInside.color, light.colors.border);
      expect(table.border!.horizontalInside.width, 1);
    });
  });
}

const _boxed = AppDataTable(
  columns: <String>['Plan', 'Price', 'Recommended'],
  rows: <List<String>>[
    <String>['Free', r'$0', ''],
    <String>['Team', r'$12', 'Best for small crews'],
  ],
  accentColumn: 2,
);

const _docs = AppDataTable(
  columns: <String>['Name', 'Kind'],
  rows: <List<String>>[
    <String>['ring marker', 'signature'],
    <String>['wordmark', 'signature'],
  ],
  style: AppDataTableStyle.docs,
);

Color _textColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

Widget _harness({required Widget child, Brightness brightness = Brightness.light}) {
  final theme = brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: theme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
