import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/glass/glass_dock.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';

void main() {
  final theme = generated.lightTheme;

  testWidgets('renders the pill dock with one composed blur layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          actions: <GlassDockAction>[
            GlassDockAction(
              icon: FLucideIcons.search,
              semanticLabel: 'Search',
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
      theme.style.borderRadius.pill,
    );

    // The dock carries the deeper shadow on top of the two recipe lines.
    expect(_dockShadows(tester), hasLength(3));
  });

  testWidgets('icon controls carry their caller-provided labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          actions: <GlassDockAction>[
            GlassDockAction(
              icon: FLucideIcons.search,
              semanticLabel: 'Search the library',
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Search the library'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('tapping a control fires its action', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _harness(
        child: GlassDock(
          actions: <GlassDockAction>[
            GlassDockAction(
              icon: FLucideIcons.play,
              semanticLabel: 'Play',
              onPressed: () => pressed++,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Play'));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('Enter and Space activate the focused control', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _harness(
        child: GlassDock(
          actions: <GlassDockAction>[
            GlassDockAction(
              icon: FLucideIcons.play,
              semanticLabel: 'Play',
              onPressed: () => pressed++,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // The dock's control is the only focusable widget in the harness.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(pressed, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, 2);
  });

  testWidgets('disabled controls are inert and half-transparent', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          actions: <GlassDockAction>[
            GlassDockAction(
              icon: FLucideIcons.pause,
              semanticLabel: 'Pause',
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final node = tester.getSemantics(find.bySemanticsLabel('Pause'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(
      find.byWidgetPredicate((widget) => widget is Opacity && widget.opacity == 0.5),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('fallback drops the blur and fills with the card color', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          fallback: true,
          actions: <GlassDockAction>[
            GlassDockAction(
              icon: FLucideIcons.search,
              semanticLabel: 'Search',
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BackdropFilter), findsNothing);
    final painter = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is GlassEdgePainter,
      ),
    );
    expect((painter.painter! as GlassEdgePainter).style.blurSigma, isNull);
    expect(
      (painter.painter! as GlassEdgePainter).style.wash,
      theme.colors.card,
    );
  });

  for (final variant in GlassVariant.values) {
    testWidgets('dock accepts the $variant recipe', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: GlassDock(
            variant: variant,
            actions: const <GlassDockAction>[
              GlassDockAction(
                icon: FLucideIcons.search,
                semanticLabel: 'Search',
                onPressed: _noop,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final painter = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is GlassEdgePainter,
        ),
      );
      final style = painter.painter! as GlassEdgePainter;
      final sigma = switch (variant) {
        GlassVariant.smoke => 16.0,
        GlassVariant.clear => 6.0,
        GlassVariant.frost || GlassVariant.tint => 11.0,
      };
      expect(style.style.blurSigma, sigma);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  }
}

void _noop() {}

Widget _harness({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      // A colored backdrop so the dock floats over something real.
      child: Scaffold(
        body: ColoredBox(
          color: const Color(0xFF0E7490),
          child: Center(child: child),
        ),
      ),
    ),
  );
}

List<BoxShadow> _dockShadows(WidgetTester tester) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(GlassDock),
          matching: find.byWidgetPredicate(
            (widget) => widget is DecoratedBox && widget.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return (decoratedBox.decoration as BoxDecoration).boxShadow!;
}
