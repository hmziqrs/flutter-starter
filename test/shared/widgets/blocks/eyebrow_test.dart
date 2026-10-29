import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/eyebrow.dart';

void main() {
  group('AppEyebrow', () {
    testWidgets('ring draws a 20px primary circle with an 11dp tabular digit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppEyebrow('Where the work goes', index: 2),
          theme: generated.lightTheme,
        ),
      );

      final colors = generated.lightTheme.colors;
      final ring = tester.widget<Container>(find.byWidgetPredicate(_isRingMark));
      expect(tester.getSize(find.byWidget(ring)), const Size(20, 20));
      final ringDecoration = ring.decoration! as ShapeDecoration;
      final ringShape = ringDecoration.shape as CircleBorder;
      expect(ringShape.side.color, colors.primary);
      expect(ringShape.side.width, generated.lightTheme.style.borderWidth);

      final digit = tester.widget<Text>(find.text('2'));
      expect(digit.style!.fontSize, 11);
      expect(digit.style!.height, 1);
      expect(digit.style!.color, colors.primary);
      expect(digit.style!.fontFeatures, const [FontFeature.tabularFigures()]);

      final label = tester.widget<Text>(find.text('Where the work goes'));
      expect(label.style!.fontSize, 13);
      expect(label.style!.fontWeight, FontWeight.w500);
      expect(label.style!.color, colors.primary);
    });

    testWidgets('rule draws a 32x1 primary mark and leaves the words muted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppEyebrow('Where the work goes', variant: AppEyebrowVariant.rule),
          theme: generated.darkTheme,
        ),
      );

      final colors = generated.darkTheme.colors;
      final rule = tester.getSize(find.byWidgetPredicate(_isRuleMark));
      expect(rule, const Size(32, 1));

      expect(
        tester.widget<Text>(find.text('Where the work goes')).style!.color,
        colors.mutedForeground,
      );
    });

    testWidgets('count draws one 2x12 tick per step, filled up to the index', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppEyebrow(
            'Where the work goes',
            variant: AppEyebrowVariant.count,
            index: 3,
            total: 5,
          ),
          theme: generated.darkTheme,
        ),
      );

      final colors = generated.darkTheme.colors;
      final ticks = tester
          .widgetList<Container>(find.byWidgetPredicate(_isTick))
          .toList(growable: false);
      expect(ticks.length, 5);
      expect(
        ticks.map((tick) => (tick.decoration! as ShapeDecoration).color),
        <Color?>[
          colors.primary,
          colors.primary,
          colors.primary,
          colors.border,
          colors.border,
        ],
      );
      expect(
        tester.getSize(find.byWidget(ticks.first)),
        const Size(2, 12),
      );

      // gap-1 between the ticks.
      expect(
        tester.widgetList<SizedBox>(find.byType(SizedBox)).where((box) => box.width == 4).length,
        4,
      );
    });
  });
}

bool _isRingMark(Widget widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  return decoration is ShapeDecoration && decoration.shape is CircleBorder;
}

bool _isRuleMark(Widget widget) {
  // Container(width: 32, height: 1, color: ...) carries its size as tight
  // additional constraints; the width/height fields have no public getters.
  return widget is Container &&
      widget.color != null &&
      widget.constraints == const BoxConstraints.tightFor(width: 32, height: 1);
}

bool _isTick(Widget widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  return decoration is ShapeDecoration && decoration.shape is StadiumBorder;
}

Widget _harness({required Widget child, required FThemeData theme}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: theme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
