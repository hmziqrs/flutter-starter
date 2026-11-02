import 'dart:ui' show SemanticsAction, Tristate;

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
          actions: <GlassDockEntry>[
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

    // The dock is a plain glass pill like the web kit's: exactly the two
    // recipe shadows, no extra floating depth.
    expect(_dockShadows(tester), hasLength(2));
  });

  testWidgets('icon controls carry their caller-provided labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          actions: <GlassDockEntry>[
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
          actions: <GlassDockEntry>[
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
          actions: <GlassDockEntry>[
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
          actions: <GlassDockEntry>[
            GlassDockAction(icon: FLucideIcons.pause, semanticLabel: 'Pause'),
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

  testWidgets('a pressed control reads the aria-pressed wash and flag', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          actions: <GlassDockEntry>[
            GlassDockAction(
              icon: FLucideIcons.listTree,
              semanticLabel: 'Contents',
              pressed: true,
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // The pressed pill: foreground at 10% (the web kit's
    // aria-pressed:bg-foreground/10).
    final pill = tester.widget<DecoratedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    expect(
      (pill.decoration as BoxDecoration).color,
      theme.colors.foreground.withValues(alpha: 0.1),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Contents')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    handle.dispose();
  });

  testWidgets('a labeled control renders its label in a full pill', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          actions: <GlassDockEntry>[
            GlassDockAction(
              icon: FLucideIcons.listTree,
              label: 'Contents',
              semanticLabel: 'Contents',
              pressed: true,
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // The visible label rides beside the icon (the web kit's
    // `hidden sm:inline` label), inside a pill pinned at the web button's
    // h-9, washed with the aria-pressed foreground at 10%.
    expect(find.text('Contents'), findsOneWidget);
    final pill = tester.widget<DecoratedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.rectangle &&
            (widget.decoration as BoxDecoration).borderRadius == BorderRadius.circular(999),
      ),
    );
    expect(
      (pill.decoration as BoxDecoration).color,
      theme.colors.foreground.withValues(alpha: 0.1),
    );
    expect(tester.getSize(find.byWidget(pill)).height, 36);
    handle.dispose();
  });

  testWidgets('below the sm breakpoint the label hides and the pill goes '
      "icon-only at the web button's px-3", (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        child: const GlassDock(
          actions: <GlassDockEntry>[
            GlassDockAction(
              icon: FLucideIcons.listTree,
              label: 'Contents',
              semanticLabel: 'Contents',
              onPressed: _noop,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // The visible label is gone (the web kit's `hidden sm:inline`), the
    // control is the 16px icon inside the web button's px-3 (40 wide at
    // h-9), and semantics still announce the action.
    expect(find.text('Contents'), findsNothing);
    final button = find.ancestor(
      of: find.byIcon(FLucideIcons.listTree),
      matching: find.byWidgetPredicate((widget) => widget is SizedBox && widget.height == 36),
    );
    expect(tester.getSize(button.first).width, 40);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Contents')),
      isNotNull,
    );
    handle.dispose();
  });

  testWidgets('separators, lead and a trailing action join the row', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        child: GlassDock(
          lead: const Text('3 selected'),
          actions: const <GlassDockEntry>[
            GlassDockAction(
              icon: FLucideIcons.archive,
              semanticLabel: 'Archive',
              onPressed: _noop,
            ),
            GlassDockSeparator(),
            GlassDockAction(
              icon: FLucideIcons.trash2,
              semanticLabel: 'Delete',
              onPressed: _noop,
            ),
          ],
          action: FButton(onPress: () {}, child: const Text('Done')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('3 selected'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    // Two hairlines flank the groups: one after the lead, one inside the
    // entries, and one before the action — three separators total.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.color == theme.colors.border &&
            widget.child is SizedBox &&
            (widget.child! as SizedBox).width == 1,
      ),
      findsNWidgets(3),
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
          actions: <GlassDockEntry>[
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
    expect((painter.painter! as GlassEdgePainter).style.wash, theme.colors.card);
  });

  for (final variant in GlassVariant.values) {
    testWidgets('dock accepts the $variant recipe', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: GlassDock(
            variant: variant,
            actions: const <GlassDockEntry>[
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
