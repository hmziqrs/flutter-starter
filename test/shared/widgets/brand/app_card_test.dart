import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/containers/app_card.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders as a brand outline card: no fill, 1px border, no shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(child: const AppCard(child: Text('Card body'))),
      );
      await tester.pump();

      expect(find.text('Card body'), findsOneWidget);
      final decoration = _cardDecoration(tester);
      // A null ShapeDecoration fill paints nothing, which is the outline
      // card's transparent fill.
      final fill = decoration.color;
      expect(fill == null || fill == Colors.transparent, isTrue);
      expect(decoration.shadows, isNull);
      final shape = decoration.shape as RoundedSuperellipseBorder;
      expect(shape.side.color, generated.lightTheme.colors.border);
      expect(shape.side.width, generated.lightTheme.style.borderWidth);
    });

    testWidgets('hover tints the border toward primary and moves nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(child: const AppCard(child: Text('Card body'))),
      );
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(AppCard)));
      await tester.pump();

      final hovered = _cardDecoration(tester).shape as RoundedSuperellipseBorder;
      expect(
        hovered.side.color,
        generated.lightTheme.colors.primary.withValues(alpha: 0.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the public API: padding, style, clipBehavior, child', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppCard(
            padding: EdgeInsets.all(42),
            clipBehavior: Clip.antiAlias,
            child: Text('Card body'),
          ),
        ),
      );
      await tester.pump();

      final padding = tester.widget<Padding>(
        find.descendant(of: find.byType(AppCard), matching: find.byType(Padding)).first,
      );
      expect(padding.padding, const EdgeInsets.all(42));
      expect(tester.widget<FCard>(find.byType(FCard)).clipBehavior, Clip.antiAlias);
    });

    testWidgets('a caller style delta resolves over the outline base', (tester) async {
      final customStyle = FCardStyle(
        decoration: const ShapeDecoration(
          color: Colors.transparent,
          shape: StadiumBorder(),
        ),
        titleTextStyle: const TextStyle(),
        subtitleTextStyle: const TextStyle(),
      );
      await tester.pumpWidget(
        _harness(
          child: AppCard(style: customStyle, child: const Text('Card body')),
        ),
      );
      await tester.pump();

      final resolved = tester
          .widget<FCard>(find.byType(FCard))
          .style(generated.lightTheme.cardStyle);
      expect(resolved, customStyle);
    });
  });
}

ShapeDecoration _cardDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(FCard),
          matching: find.byWidgetPredicate((widget) => widget is DecoratedBox),
        )
        .first,
  );
  return box.decoration as ShapeDecoration;
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
