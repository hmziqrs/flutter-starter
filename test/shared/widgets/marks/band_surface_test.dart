import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/band_surface.dart';

final Finder _bandBox = find.descendant(
  of: find.byType(BandSurface),
  matching: find.byWidgetPredicate((widget) => widget is Container && widget.color != null),
);

void main() {
  group('BandSurface', () {
    testWidgets('fills with the light band neutral and keeps square edges', (tester) async {
      await tester.pumpWidget(_harness(brightness: Brightness.light));

      expect(tester.widget<Container>(_bandBox).color, generated.lightTheme.colors.muted);
      expect(tester.getSize(find.byType(BandSurface)).width, 800);
    });

    testWidgets('fills with the dark band neutral', (tester) async {
      await tester.pumpWidget(_harness(brightness: Brightness.dark));

      expect(tester.widget<Container>(_bandBox).color, generated.darkTheme.colors.card);
    });
  });
}

Widget _harness({required Brightness brightness}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme,
      child: const Scaffold(
        body: BandSurface(child: Column(children: <Widget>[Text('Key numbers')])),
      ),
    ),
  );
}
