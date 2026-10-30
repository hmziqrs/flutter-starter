import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

/// Brand button contract, measured from the brand kit's
/// `packages/brand-svelte/src/lib/ui/button/button.svelte`:
///
/// * md (default) h-9 px-2.5 gap-1.5 -> 36 tall, 10 horizontal, 6 gap
/// * sm            h-8 px-2.5 gap-1   -> 32 tall, 10 horizontal, 4 gap
/// * lg            h-10 px-2.5 gap-1.5 -> 40 tall, 10 horizontal, 6 gap
/// * xs            h-6 px-2 gap-1     -> 24 tall, 8 horizontal, 4 gap
/// * icon buttons are square at the size height, rounded-md,
///   text-sm (14px, 12px on xs) font-medium (w500).
/// * in-button svg glyphs are pinned at size-4 (16px), size-3 (12px) on xs
///   (button.svelte base + xs size classes), for label and icon-only alike.
/// * hover/press/focus feedback is COLOR ONLY (BRAND.md s8) — a held press
///   must not scale, translate or rotate the button.
///
/// The brand heights render in every input model — the touch policy adds no
/// inflation (the kit's buttons are the same size on a phone as on a desktop).
typedef _BrandMetrics = ({double height, double horizontal, double gap, double iconSize});

final _brand = <FButtonSizeVariant, _BrandMetrics>{
  FButtonSizeVariant.xs: (height: 24, horizontal: 8, gap: 4, iconSize: 12),
  FButtonSizeVariant.sm: (height: 32, horizontal: 10, gap: 4, iconSize: 16),
  FButtonSizeVariant.md: (height: 36, horizontal: 10, gap: 6, iconSize: 16),
  FButtonSizeVariant.lg: (height: 40, horizontal: 10, gap: 6, iconSize: 16),
};

/// Label buttons on touch: the same brand heights.
final _touchLabelHeights = <FButtonSizeVariant, double>{
  FButtonSizeVariant.xs: 24,
  FButtonSizeVariant.sm: 32,
  FButtonSizeVariant.md: 36,
  FButtonSizeVariant.lg: 40,
};

/// Icon buttons are square at the size height, in every input model.
final _touchIconHeights = <FButtonSizeVariant, double>{
  FButtonSizeVariant.xs: 24,
  FButtonSizeVariant.sm: 32,
  FButtonSizeVariant.md: 36,
  FButtonSizeVariant.lg: 40,
};

const _label = 'Save';

void main() {
  final policies = <(AppInteractionPolicy, String)>[
    (AppInteractionPolicy.precisionPointer, 'desktop precision-pointer'),
    (AppInteractionPolicy.touch, 'touch'),
  ];

  for (final (policy, policyName) in policies) {
    final isDesktop = policy == AppInteractionPolicy.precisionPointer;

    for (final size in _brand.keys) {
      final brand = _brand[size]!;
      final expectedLabelHeight = isDesktop ? brand.height : _touchLabelHeights[size]!;
      final expectedIconHeight = isDesktop ? brand.height : _touchIconHeights[size]!;

      testWidgets('FButton $size label metrics match the brand kit ($policyName)', (tester) async {
        final theme = _theme(policy);
        final style = _styleFor(theme, size);

        await tester.pumpWidget(_frame(theme, _labelButton(size)));

        final button = find.byType(FButton);
        final box = tester.getSize(button);
        final padding = _contentPadding(tester, button);
        final textStyle = _labelStyle(tester);

        debugPrint(
          '[button-metrics] $policyName $size label: ${box.width}x${box.height} '
          'padding=$padding gap=${_rowGap(tester, button)} '
          'fontSize=${textStyle.fontSize} weight=${textStyle.fontWeight}',
        );

        expect(box.height, expectedLabelHeight);
        expect(padding.left, brand.horizontal);
        expect(padding.right, brand.horizontal);
        // Vertical padding centers the tallest glyph (label or pinned svg).
        expect(padding.vertical, brand.height - math.max(textStyle.fontSize!, brand.iconSize));
        expect(_rowGap(tester, button), brand.gap);
        expect(textStyle.fontSize, size == FButtonSizeVariant.xs ? 12 : 14);
        expect(textStyle.fontWeight, FontWeight.w500);
        // The rendered content padding and gap come straight from the style.
        expect(style.contentStyle.padding.resolve(TextDirection.ltr), padding);
        expect(style.contentStyle.spacing, brand.gap);
        expect(style.contentStyle.textStyle.base.fontWeight, FontWeight.w500);
      });

      testWidgets('FButton $size label+icon metrics match the brand kit ($policyName)', (
        tester,
      ) async {
        final theme = _theme(policy);

        await tester.pumpWidget(_frame(theme, _labelIconButton(size)));

        final button = find.byType(FButton);
        final box = tester.getSize(button);
        final padding = _contentPadding(tester, button);
        final textStyle = _labelStyle(tester);

        debugPrint(
          '[button-metrics] $policyName $size label+icon: ${box.width}x${box.height} '
          'padding=$padding gap=${_rowGap(tester, button)} '
          'icon=${tester.getSize(_icon(button))} weight=${textStyle.fontWeight}',
        );

        expect(box.height, expectedLabelHeight);
        expect(padding.left, brand.horizontal);
        expect(padding.right, brand.horizontal);
        expect(_rowGap(tester, button), brand.gap);
        // button.svelte: in-button svg pinned at size-4 (16), size-3 (12) on xs.
        expect(tester.getSize(_icon(button)), Size.square(brand.iconSize));
        expect(textStyle.fontWeight, FontWeight.w500);
      });

      testWidgets('FButton.icon $size is square at the size height ($policyName)', (tester) async {
        final theme = _theme(policy);

        await tester.pumpWidget(_frame(theme, _iconButton(size)));

        final button = find.byType(FButton);
        final box = tester.getSize(button);
        final padding = _contentPadding(tester, button);

        debugPrint(
          '[button-metrics] $policyName $size icon-only: ${box.width}x${box.height} '
          'padding=$padding icon=${tester.getSize(_icon(button))}',
        );

        expect(box.height, expectedIconHeight);
        expect(box.width, expectedIconHeight);
        expect(tester.getSize(_icon(button)), Size.square(brand.iconSize));
      });
    }

    testWidgets(
      'press feedback is color only — a held press never scales the button ($policyName)',
      (
        tester,
      ) async {
        final theme = _theme(policy);

        await tester.pumpWidget(_frame(theme, _labelButton(FButtonSizeVariant.md)));

        // BRAND.md s8: hover/press/focus feedback is COLOR ONLY. ForUI's default
        // tappable motion bounces the button to 0.97 on tap-down (FTappableMotion
        // .defaultBounceTween); the factory pins FTappableMotion.none so the
        // paint-time transform stays identity through a held press.
        final button = find.byType(FButton);
        final gesture = await tester.startGesture(tester.getCenter(button));
        await tester.pump(const Duration(milliseconds: 400));

        // RenderBounce applies its press scale at picture level (pushTransform
        // with needsCompositing false), which neither getTransformTo nor
        // tester.layers can observe — so the scale is pinned through the input
        // RenderBounce reads: the motion. FTappableMotion.none's tween is
        // 1.0 -> 1.0, which forces RenderBounce.paint's early return, so no
        // transform can exist. The size check below guards the rest.
        final scale = tester
            .renderObject<RenderParagraph>(find.text(_label))
            .getTransformTo(null)
            .getMaxScaleOnAxis();
        debugPrint('[button-metrics] $policyName held-press label scale: $scale');

        expect(tester.getSize(button).height, expectedLabelHeightForMd(policy));
        expect(scale, 1.0);
        expect(theme.style.tappableStyle.motion, same(FTappableMotion.none));
        final style = _styleFor(theme, FButtonSizeVariant.md);
        expect(style.tappableStyle.motion, same(FTappableMotion.none));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  }

  test('button corner radius stays on the brand rounded-md token', () {
    final theme = _theme(AppInteractionPolicy.precisionPointer);
    // BRAND.md section 3: --radius-md = calc(var(--radius) - 2px) = 8px, the
    // ForUI sm token. Every size paints it — the kit's xs/sm caps,
    // rounded-[min(var(--radius-md), 8/10px)], also resolve to 8 — and so do
    // the icon buttons and every interactive state.
    expect(theme.style.borderRadius.sm, BorderRadius.circular(8));

    BorderRadius radiusFor(FButtonSizeVariant size) {
      final decoration = _styleFor(theme, size).decoration.base as ShapeDecoration;
      final border = decoration.shape as RoundedSuperellipseBorder;
      return border.borderRadius.resolve(TextDirection.ltr);
    }

    for (final size in _brand.keys) {
      expect(radiusFor(size), BorderRadius.circular(8));
    }

    final hoveredPressed =
        _styleFor(theme, FButtonSizeVariant.md).decoration.resolve(
              <FVariant>{FTappableVariant.hovered, FTappableVariant.pressed},
            )
            as ShapeDecoration;
    final hoveredBorder = hoveredPressed.shape as RoundedSuperellipseBorder;
    expect(hoveredBorder.borderRadius.resolve(TextDirection.ltr), BorderRadius.circular(8));
  });
}

FThemeData _theme(AppInteractionPolicy policy) => ForuiThemeFactory.build(
  brightness: Brightness.light,
  accent: AppAccent.neutral,
  fontScale: 1,
  interactionPolicy: policy,
);

FButtonStyle _styleFor(FThemeData theme, FButtonSizeVariant size) =>
    theme.buttonStyles.resolve(<FVariant>{FButtonVariant.primary}).resolve(<FVariant>{size});

/// Brand md height on desktop; the touch a11y floor on touch.
// The brand md height renders in every input model — no touch inflation.
double expectedLabelHeightForMd(AppInteractionPolicy policy) => 36;

Widget _frame(FThemeData theme, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: FTheme(
    data: theme,
    child: Center(child: child),
  ),
);

FButton _labelButton(FButtonSizeVariant size) => FButton(
  onPress: () {},
  size: size,
  mainAxisSize: MainAxisSize.min,
  child: const Text(_label),
);

FButton _labelIconButton(FButtonSizeVariant size) => FButton(
  onPress: () {},
  size: size,
  mainAxisSize: MainAxisSize.min,
  prefix: const Icon(FLucideIcons.plus),
  child: const Text(_label),
);

FButton _iconButton(FButtonSizeVariant size) =>
    FButton.icon(onPress: () {}, size: size, child: const Icon(FLucideIcons.plus));

EdgeInsets _contentPadding(WidgetTester tester, Finder button) => tester
    .widget<Padding>(find.descendant(of: button, matching: find.byType(Padding)).first)
    .padding
    .resolve(TextDirection.ltr);

double? _rowGap(WidgetTester tester, Finder button) =>
    tester.widget<Row>(find.descendant(of: button, matching: find.byType(Row))).spacing;

Finder _icon(Finder button) => find.descendant(of: button, matching: find.byType(Icon));

TextStyle _labelStyle(WidgetTester tester) =>
    (tester.renderObject<RenderParagraph>(find.text(_label)).text as TextSpan).style!;
