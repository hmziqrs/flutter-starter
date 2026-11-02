import 'dart:ui' as ui show Image;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/oklab.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/glass/glass_panel.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';

void main() {
  final theme = generated.lightTheme;
  final background = theme.colors.background;
  final foreground = theme.colors.foreground;
  final primary = theme.colors.primary;

  // The recipe each variant must resolve to (glass.css values; sigma is the
  // CSS blur radius divided by two).
  final expected = <GlassVariant, ({double sigma, Color wash, Color edge, Color shine})>{
    GlassVariant.frost: (
      sigma: 11,
      wash: background.withValues(alpha: 0.64),
      edge: foreground.withValues(alpha: 0.14),
      shine: foreground.withValues(alpha: 0.22),
    ),
    GlassVariant.smoke: (
      sigma: 16,
      wash: background.withValues(alpha: 0.8),
      edge: foreground.withValues(alpha: 0.14),
      shine: foreground.withValues(alpha: 0.22),
    ),
    GlassVariant.tint: (
      sigma: 11,
      // glass.css mixes the tint wash in oklab.
      wash: oklabMix(background, primary, 0.16).withValues(alpha: 0.66),
      edge: primary.withValues(alpha: 0.3),
      shine: primary.withValues(alpha: 0.45),
    ),
    GlassVariant.clear: (
      sigma: 6,
      wash: background.withValues(alpha: 0.34),
      edge: foreground.withValues(alpha: 0.14),
      shine: foreground.withValues(alpha: 0.3),
    ),
  };

  for (final entry in expected.entries) {
    final variant = entry.key;
    final recipe = entry.value;
    testWidgets('renders $variant over a colored backdrop', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: GlassPanel(
            variant: variant,
            child: const SizedBox(
              width: 240,
              height: 96,
              child: Center(child: Text('content')),
            ),
          ),
        ),
      );
      await tester.pump();

      // Exactly one BackdropFilter per panel, composed and clipped.
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
      expect(
        tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
        theme.style.borderRadius.lg,
      );
      expect(find.text('content'), findsOneWidget);

      // The wash over the blurred backdrop.
      final wash = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(BackdropFilter),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(wash.color, recipe.wash);

      // The border work: edge, shine and inset highlight per variant, and a
      // blur sigma derived from the CSS radius.
      final painter = _edgePainter(tester);
      expect(painter.style.blurSigma, recipe.sigma);
      expect(painter.style.edge, recipe.edge);
      expect(painter.style.shine, recipe.shine);
      expect(painter.style.insetHighlight, foreground.withValues(alpha: 0.1));

      // The soft shadows: the two glass.css lines, no more.
      final shadows = _panelShadows(tester);
      expect(shadows, hasLength(2));
      expect(
        shadows.first,
        BoxShadow(
          color: background.withValues(alpha: 0.3),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      );
    });
  }

  testWidgets('fallback renders the solid card and no blur layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        child: const GlassPanel(
          fallback: true,
          child: SizedBox(
            width: 240,
            height: 96,
            child: Center(child: Text('content')),
          ),
        ),
      ),
    );
    await tester.pump();

    // No BackdropFilter anywhere in the panel.
    expect(find.byType(BackdropFilter), findsNothing);

    // The fill is the solid card color.
    final wash = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(GlassPanel),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(wash.color, theme.colors.card);

    // The border and shine stay, and so do the shadows.
    final painter = _edgePainter(tester);
    expect(painter.style.blurSigma, isNull);
    expect(painter.style.edge, foreground.withValues(alpha: 0.14));
    expect(painter.style.shine, foreground.withValues(alpha: 0.22));
    expect(_panelShadows(tester), hasLength(2));
  });

  testWidgets('a radius override reaches the clip and the decoration', (
    tester,
  ) async {
    const radius = BorderRadius.all(Radius.circular(24));
    await tester.pumpWidget(
      _harness(
        child: const GlassPanel(radius: radius, child: SizedBox(width: 80)),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius,
      radius,
    );
    expect(_edgePainter(tester).style.radius, radius);
  });

  testWidgets('grain mounts a painted tile in one frame, deterministically', (
    tester,
  ) async {
    // The tile is rendered synchronously (Picture.toImageSync): the first
    // frame already carries the grain. An async decode would leave the
    // panel grainless for its first frames — permanently under the
    // fake-async pumps of tests and goldens, which never settle engine
    // futures.
    await tester.pumpWidget(
      _harness(
        child: const GlassPanel(grain: true, child: SizedBox(width: 80)),
      ),
    );
    await tester.pump();

    expect(_grainOverlayFinder(), findsOneWidget);
    final painter = tester.widget<CustomPaint>(
      find
          .descendant(
            of: _grainOverlayFinder(),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint &&
                  widget.painter != null &&
                  widget.painter!.runtimeType.toString() == '_GrainPainter',
            ),
          )
          .first,
    );
    // A real 160x160 tile rides the painter, seeded so the same seed always
    // draws the same grain.
    final tile = (painter.painter! as dynamic).tile as ui.Image;
    expect(tile.width, 160);
    expect(tile.height, 160);

    await tester.pumpWidget(
      _harness(child: const GlassPanel(child: SizedBox(width: 80))),
    );
    await tester.pump();

    expect(_grainOverlayFinder(), findsNothing);
  });

  testWidgets('padding wraps the child inside the panel', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: const GlassPanel(
          padding: EdgeInsets.all(16),
          child: SizedBox(width: 50, height: 50),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(GlassPanel)), const Size(82, 82));
  });

  testWidgets('glass never nests inside glass', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: const GlassPanel(
          child: GlassPanel(child: SizedBox(width: 40)),
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isA<FlutterError>());
    expect(
      (exception! as FlutterError).message,
      contains('Glass never nests inside glass'),
    );
  });
}

Widget _harness({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      // A colored backdrop so the glass has something real behind it.
      child: Scaffold(
        body: ColoredBox(
          color: const Color(0xFF0E7490),
          child: Center(child: child),
        ),
      ),
    ),
  );
}

GlassEdgePainter _edgePainter(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is GlassEdgePainter,
    ),
  );
  return customPaint.painter! as GlassEdgePainter;
}

List<BoxShadow> _panelShadows(WidgetTester tester) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(GlassPanel),
          matching: find.byWidgetPredicate(
            (widget) => widget is DecoratedBox && widget.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return (decoratedBox.decoration as BoxDecoration).boxShadow!;
}

Finder _grainOverlayFinder() {
  return find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_GrainOverlay',
  );
}
