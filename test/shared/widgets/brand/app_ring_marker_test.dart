import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

void main() {
  group('AppRingMarker', () {
    testWidgets('is a hollow 1.75px ring by default', (tester) async {
      await tester.pumpWidget(_harness(child: const AppRingMarker()));
      await tester.pump();

      final decoration = _markerDecoration(tester);
      final shape = decoration.shape as CircleBorder;
      expect(shape.side.width, 1.75);
      expect(decoration.color, Colors.transparent);
      expect(tester.getSize(find.byType(AppRingMarker)), const Size(9, 9));
    });

    testWidgets('filled paints the disc in the marker color', (tester) async {
      const tone = Color(0xFF5DC879);
      await tester.pumpWidget(
        _harness(child: const AppRingMarker(filled: true, color: tone)),
      );
      await tester.pump();

      final decoration = _markerDecoration(tester);
      expect(decoration.color, tone);
      expect((decoration.shape as CircleBorder).side.color, tone);
    });

    testWidgets('unfilled keeps the ring colored and the disc clear', (tester) async {
      const tone = Color(0xFFCD1622);
      await tester.pumpWidget(_harness(child: const AppRingMarker(color: tone)));
      await tester.pump();

      final decoration = _markerDecoration(tester);
      expect((decoration.shape as CircleBorder).side.color, tone);
      expect(decoration.color, Colors.transparent);
    });

    testWidgets('without a color it takes the surrounding text color', (tester) async {
      const textColor = Color(0xFF123456);
      await tester.pumpWidget(
        _harness(
          child: const DefaultTextStyle(
            style: TextStyle(color: textColor),
            child: AppRingMarker(),
          ),
        ),
      );
      await tester.pump();

      expect(
        (_markerDecoration(tester).shape as CircleBorder).side.color,
        textColor,
      );
    });
  });
}

ShapeDecoration _markerDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(AppRingMarker),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as ShapeDecoration;
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
