import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/segmented.dart';

void main() {
  group('AppSegmented', () {
    for (final brightness in Brightness.values) {
      final isDark = brightness == Brightness.dark;
      final fillOpacity = isDark ? 0.20 : 0.10;
      final theme = isDark ? generated.darkTheme : generated.lightTheme;

      testWidgets(
        'gives the picked option the soft primary fill and primary text at $brightness',
        (tester) async {
          await tester.pumpWidget(
            _harness(
              brightness: brightness,
              child: const _Segmented(value: 'weekly'),
            ),
          );

          final selected = _segmentDecoration(tester, 'Weekly');
          expect(selected.color, theme.colors.primary.withValues(alpha: fillOpacity));
          expect(_textColor(tester, 'Weekly'), theme.colors.primary);

          // The resting option stays on the muted foreground, unfilled.
          expect(_segmentDecoration(tester, 'Daily').color!.a, 0);
          expect(_textColor(tester, 'Daily'), theme.colors.mutedForeground);
        },
      );
    }

    testWidgets('reports the newly picked value and moves the fill', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _harness(
          child: _Segmented(value: 'weekly', onChanged: picked.add),
        ),
      );

      await tester.tap(find.text('Daily'));
      await tester.pump();

      expect(picked, <String>['daily']);
      final light = generated.lightTheme;
      expect(
        _segmentDecoration(tester, 'Daily').color,
        light.colors.primary.withValues(alpha: 0.10),
      );
      expect(_segmentDecoration(tester, 'Weekly').color!.a, 0);
    });
  });
}

class _Segmented extends StatefulWidget {
  const _Segmented({required this.value, this.onChanged});

  final String value;

  final ValueChanged<String>? onChanged;

  @override
  State<_Segmented> createState() => _SegmentedState();
}

class _SegmentedState extends State<_Segmented> {
  late String value = widget.value;

  @override
  Widget build(BuildContext context) {
    return AppSegmented<String>(
      options: const <AppSegmentOption<String>>[
        (value: 'daily', label: 'Daily'),
        (value: 'weekly', label: 'Weekly'),
      ],
      value: value,
      onChanged: (next) {
        setState(() => value = next);
        widget.onChanged?.call(next);
      },
    );
  }
}

ShapeDecoration _segmentDecoration(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is ShapeDecoration &&
                (widget.decoration! as ShapeDecoration).shape is RoundedSuperellipseBorder,
          ),
        )
        .first,
  );
  return container.decoration! as ShapeDecoration;
}

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
