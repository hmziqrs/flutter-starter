import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/marks/element_card.dart';
import 'package:starter/shared/widgets/rings/corner_rings.dart';

ElementCard _card() => ElementCard(
  number: 6,
  symbol: 'Gq',
  name: 'gpui-query',
  description: 'Load data in GPUI apps without writing the plumbing.',
  kind: 'Library',
  seed: 'gpui-query',
  kindColor: AppBrandColors.light.blue,
  statusLabel: 'Shipped',
);

final Finder _cardOutline = find.byWidgetPredicate(
  (widget) => widget is DecoratedBox && widget.decoration is ShapeDecoration,
);

void main() {
  group('ElementCard', () {
    testWidgets('paints the corner rings first, under everything else', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 320, child: _card())));

      final stack = tester.widget<Stack>(
        find.descendant(of: find.byType(ElementCard), matching: find.byType(Stack)),
      );
      expect(stack.children.first, isA<Positioned>());
      expect(
        (stack.children.first as Positioned).width,
        closeTo(320 * 0.7, 0.001),
      );
      final rings = tester.widget<CornerRings>(
        find.descendant(of: find.byType(ElementCard), matching: find.byType(CornerRings)),
      );
      expect(rings.seed, 'gpui-query');
      expect(rings.accentColor, AppBrandColors.light.blue);
    });

    testWidgets('orders number, symbol, name, description, kind from the top', (tester) async {
      await tester.pumpWidget(
        _harness(child: SizedBox(width: 320, height: 400, child: _card())),
      );

      double topOf(String text) => tester.getTopLeft(find.text(text)).dy;
      final order = <double>[
        topOf('06'),
        topOf('Gq'),
        topOf('gpui-query'),
        topOf('Load data in GPUI apps without writing the plumbing.'),
        topOf('Library'),
      ];
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          order[i],
          lessThan(order[i + 1]),
          reason: 'entry $i must sit above entry ${i + 1}',
        );
      }
    });

    testWidgets('draws the number muted in tabular figures, symbol in the kind color', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 320, child: _card())));

      final number = tester.widget<Text>(find.text('06')).style!;
      expect(number.color, generated.lightTheme.colors.mutedForeground);
      expect(number.fontFeatures, contains(const FontFeature.tabularFigures()));

      final symbol = tester.widget<Text>(find.text('Gq')).style!;
      expect(symbol.color, AppBrandColors.light.blue);
      expect(symbol.fontWeight, FontWeight.w500);
      expect(symbol.fontSize, 44);
      expect(symbol.letterSpacing, closeTo(-0.04 * 44, 0.001));
    });

    testWidgets('pairs the kind with a ring marker in the kind color', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 320, child: _card())));

      final marker = tester.widget<AppRingMarker>(find.byType(AppRingMarker));
      expect(marker.color, AppBrandColors.light.blue);
      final markerCenter = tester.getCenter(find.byType(AppRingMarker)).dy;
      final kindCenter = tester.getCenter(find.text('Library')).dy;
      expect((markerCenter - kindCenter).abs(), lessThan(4));
    });

    testWidgets('shows the status tag to the right of the number', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 320, child: _card())));

      expect(
        tester.getTopLeft(find.text('Shipped')).dx,
        greaterThan(tester.getTopRight(find.text('06')).dx),
      );
    });

    testWidgets('keeps an outline fill and tints the border on hover', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 320, child: _card())));

      ShapeDecoration decorationOf() =>
          tester.widget<DecoratedBox>(_cardOutline.first).decoration as ShapeDecoration;
      expect(decorationOf().color, Colors.transparent);
      expect(
        (decorationOf().shape as RoundedSuperellipseBorder).side.color,
        generated.lightTheme.colors.foreground.withValues(alpha: 0.10),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(ElementCard)));
      await tester.pumpAndSettle();

      expect(
        (decorationOf().shape as RoundedSuperellipseBorder).side.color,
        // hover:ring-primary/50 — the brand tint follows the theme's
        // primary, whatever accent the theme points it at.
        generated.lightTheme.colors.primary.withValues(alpha: 0.5),
      );
    });
  });
}

Widget _harness({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
