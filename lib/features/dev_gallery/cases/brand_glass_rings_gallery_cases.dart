import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
import 'package:starter/shared/widgets/glass/glass_dock.dart';
import 'package:starter/shared/widgets/glass/glass_panel.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';
import 'package:starter/shared/widgets/glass/liquid_glass.dart';
import 'package:starter/shared/widgets/rings/band_arcs.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
import 'package:starter/shared/widgets/rings/corner_rings.dart';
import 'package:starter/shared/widgets/rings/horizon_rings.dart';
import 'package:starter/shared/widgets/rings/ring_divider.dart';
import 'package:starter/shared/widgets/rings/ring_loader.dart';
import 'package:starter/shared/widgets/rings/ring_meter.dart';
import 'package:starter/shared/widgets/rings/status_ring.dart';

/// The glass stories (BRAND.md signature surfaces, glass.css): the four
/// variants floating over scrolling content, the dock, the grain toggle, the
/// solid fallback and the liquid refraction. Dev-only surface, so the labels
/// are literal English.
enum BrandGlassGalleryKind {
  panels,
  dock,
  grain,
  fallback,
  liquid,
  overMaterial,
  liquidOverMaterial,
  overRings,
}

/// Builds the "Glass" gallery cases, one per glass capability.
List<GalleryCase> buildBrandGlassGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandGlassGalleryKind.values)
      TypedGalleryCase<BrandGlassGalleryKind>(
        id: 'brandGlass.${kind.name}',
        screenId: 'brandGlass',
        screenLabelBuilder: (_) => 'Glass',
        caseLabelBuilder: (_) => _glassCaseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _BrandGlassPreview(kind: state),
      ),
  ];
}

String _glassCaseLabel(BrandGlassGalleryKind kind) => switch (kind) {
  BrandGlassGalleryKind.panels => 'Panels over content',
  BrandGlassGalleryKind.dock => 'Dock',
  BrandGlassGalleryKind.grain => 'Grain',
  BrandGlassGalleryKind.fallback => 'Solid fallback',
  BrandGlassGalleryKind.liquid => 'Liquid glass',
  BrandGlassGalleryKind.overMaterial => 'Glass over a material',
  BrandGlassGalleryKind.liquidOverMaterial => 'Liquid lens over a material',
  BrandGlassGalleryKind.overRings => 'Rings behind glass',
};

String _glassCaseDescription(BrandGlassGalleryKind kind) => switch (kind) {
  BrandGlassGalleryKind.panels =>
    'Frost, smoke, tint and clear floating over a scrolling list. Glass carries one blur and never nests.',
  BrandGlassGalleryKind.dock =>
    'A floating pill of controls: labels ride beside the icons at reading '
        "widths and hide below the kit's sm breakpoint, like the brand "
        'storybook dock. Every control also announces what it does.',
  BrandGlassGalleryKind.grain => 'The seeded grain overlay behind the panel content.',
  BrandGlassGalleryKind.fallback =>
    'The honest degraded path: solid card fill, same border, no blur layer.',
  BrandGlassGalleryKind.liquid =>
    'Backdrop refraction through a fragment shader; frosted where the engine cannot, solid card under the fallback.',
  BrandGlassGalleryKind.overMaterial =>
    'The signature pairing: a full-bleed material stays the picture while a '
        'smoke grain panel borrows its color for the reading surface.',
  BrandGlassGalleryKind.liquidOverMaterial =>
    'The liquid lens and a formatting dock floating over etched silk. On '
        'renderers without Impeller the lens takes the honest solid path.',
  BrandGlassGalleryKind.overRings =>
    'Hero rings seeded with a name behind a frost panel: where the panel '
        'crosses the rings they soften into it, like looking through a window.',
};

/// The rings stories (BRAND.md s7): the hero picture, corner fingerprints,
/// band arcs, the horizon, the small indicators, the divider and the motion
/// presets. Dev-only surface, so the labels are literal English.
enum BrandRingsGalleryKind { hero, corner, band, horizon, indicators, divider, motion }

/// Builds the "Rings" gallery cases, one per ring piece.
List<GalleryCase> buildBrandRingsGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandRingsGalleryKind.values)
      TypedGalleryCase<BrandRingsGalleryKind>(
        id: 'brandRings.${kind.name}',
        screenId: 'brandRings',
        screenLabelBuilder: (_) => 'Rings',
        caseLabelBuilder: (_) => _ringsCaseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _BrandRingsPreview(kind: state),
      ),
  ];
}

String _ringsCaseLabel(BrandRingsGalleryKind kind) => switch (kind) {
  BrandRingsGalleryKind.hero => 'Hero rings',
  BrandRingsGalleryKind.corner => 'Corner rings',
  BrandRingsGalleryKind.band => 'Band arcs',
  BrandRingsGalleryKind.horizon => 'Horizon rings',
  BrandRingsGalleryKind.indicators => 'Loader, meter, status',
  BrandRingsGalleryKind.divider => 'Ring divider',
  BrandRingsGalleryKind.motion => 'Motion presets',
};

String _ringsCaseDescription(BrandRingsGalleryKind kind) => switch (kind) {
  BrandRingsGalleryKind.hero =>
    'Eleven rings drawn from a name; the same name always draws the same picture.',
  BrandRingsGalleryKind.corner =>
    "A card's fingerprint in its top-right corner, one ring in the card's kind.",
  BrandRingsGalleryKind.band => 'Big arcs for a closing band, bleeding off the right edge.',
  BrandRingsGalleryKind.horizon =>
    'Half rings around a sun; asleep, the sun goes out and stars come up.',
  BrandRingsGalleryKind.indicators => 'The small ring pieces: loader, meter and status.',
  BrandRingsGalleryKind.divider => 'A hairline with a ring at the end; filled means something.',
  BrandRingsGalleryKind.motion =>
    'Turn and ripple presets. Paused holds the frame; reduced motion stills it.',
};

class _BrandGlassPreview extends ConsumerWidget {
  const _BrandGlassPreview({required this.kind});

  final BrandGlassGalleryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    // Glass reads against content behind it, so the showcase pins the brand
    // accent (BRAND.md s4) no matter which accent the gallery environment
    // picked; the tint variant derives its wash from the theme primary.
    final brandTheme = ForuiThemeFactory.build(
      brightness: theme.colors.brightness,
      accent: AppAccent.oxide,
      fontScale: 1,
      interactionPolicy: ref.watch(interactionPolicyProvider),
      responsiveFontScale: context.appUnit.typographyScale,
      presentationPolicy: ref.watch(presentationPolicyProvider),
    );
    return FTheme(
      data: brandTheme,
      child: SingleChildScrollView(
        padding: context.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _CaseHeader(
              title: _glassCaseLabel(kind),
              description: _glassCaseDescription(kind),
            ),
            SizedBox(height: context.spacing.xl),
            switch (kind) {
              BrandGlassGalleryKind.panels => const _PanelsStory(),
              BrandGlassGalleryKind.dock => const _DockStory(),
              BrandGlassGalleryKind.grain => const _GrainStory(),
              BrandGlassGalleryKind.fallback => const _FallbackStory(),
              BrandGlassGalleryKind.liquid => const _LiquidStory(),
              BrandGlassGalleryKind.overMaterial => const _GlassOverMaterialStory(),
              BrandGlassGalleryKind.liquidOverMaterial => const _LiquidOverMaterialStory(),
              BrandGlassGalleryKind.overRings => const _RingsBehindGlassStory(),
            },
          ],
        ),
      ),
    );
  }
}

class _BrandRingsPreview extends ConsumerWidget {
  const _BrandRingsPreview({required this.kind});

  final BrandRingsGalleryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    // The rings' accent resolves to the theme primary, so the showcase pins
    // the oxide accent (BRAND.md s4: --primary points at --orange); under a
    // neutral accent the orange signature would go undemonstrated.
    final brandTheme = ForuiThemeFactory.build(
      brightness: theme.colors.brightness,
      accent: AppAccent.oxide,
      fontScale: 1,
      interactionPolicy: ref.watch(interactionPolicyProvider),
      responsiveFontScale: context.appUnit.typographyScale,
      presentationPolicy: ref.watch(presentationPolicyProvider),
    );
    return FTheme(
      data: brandTheme,
      child: SingleChildScrollView(
        padding: context.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _CaseHeader(
              title: _ringsCaseLabel(kind),
              description: _ringsCaseDescription(kind),
            ),
            SizedBox(height: context.spacing.xl),
            switch (kind) {
              BrandRingsGalleryKind.hero => const _HeroStory(),
              BrandRingsGalleryKind.corner => const _CornerStory(),
              BrandRingsGalleryKind.band => const _BandStory(),
              BrandRingsGalleryKind.horizon => const _HorizonStory(),
              BrandRingsGalleryKind.indicators => const _IndicatorStory(),
              BrandRingsGalleryKind.divider => const _DividerStory(),
              BrandRingsGalleryKind.motion => const _MotionStory(),
            },
          ],
        ),
      ),
    );
  }
}

/// Page title at 24 w500 tight with a 14 muted description (APP-BLOCKS.md app
/// type scale).
class _CaseHeader extends StatelessWidget {
  const _CaseHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final titleStyle = theme.typography.display.xl.copyWith(
      color: theme.colors.foreground,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.02 * (theme.typography.display.xl.fontSize ?? 24),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: titleStyle),
        SizedBox(height: context.spacing.xs),
        Text(
          description,
          style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
        ),
      ],
    );
  }
}

/// Section title at 16 w500 (APP-BLOCKS.md app type scale).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      title,
      style: theme.typography.body.md.copyWith(
        color: theme.colors.foreground,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// A muted caption under a specimen (BRAND.md s5: small labels stay sentence
/// case in muted foreground).
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      text,
      style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
    );
  }
}

/// Token names are machine values, so they run in JetBrains Mono (BRAND.md
/// s5: mono never sets headings or labels people read).
class _MonoText extends StatelessWidget {
  const _MonoText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      text,
      style: theme.typography.body.xs.copyWith(
        color: theme.colors.mutedForeground,
        fontFamily: 'JetBrains Mono',
      ),
    );
  }
}

/// The content glass floats over: a scrolling list of outline rows, so the
/// blur and the wash have real edges to sit on.
class _GlassContentList extends StatelessWidget {
  const _GlassContentList();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 40,
      itemBuilder: (context, index) {
        final indexParity = index.isEven;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
          child: Row(
            children: <Widget>[
              AppRingMarker(filled: indexParity),
              const SizedBox(width: 10),
              Expanded(child: Text('Inbox item ${index + 1}', style: theme.typography.body.sm)),
              AppStatusTag(
                label: indexParity ? 'Synced' : 'Queued',
                role: indexParity ? AppStatusRole.success : AppStatusRole.neutral,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A floating glass panel labelled with its variant; the clear variant reads
/// its secondary text in plain foreground (glass.css's remap).
class _FloatingGlassPanel extends StatelessWidget {
  const _FloatingGlassPanel({
    required this.variant,
    required this.top,
  });

  final GlassVariant variant;
  final double top;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final secondaryColor = variant == GlassVariant.clear
        ? theme.colors.foreground
        : theme.colors.mutedForeground;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: GlassPanel(
        variant: variant,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                _MonoText(variant.name),
                const Spacer(),
                Flexible(
                  child: Text(
                    switch (variant) {
                      GlassVariant.frost => 'Blur 11 over a 64% wash',
                      GlassVariant.smoke => 'Blur 16 over an 80% wash',
                      GlassVariant.tint => 'Primary-tinted wash and edge',
                      GlassVariant.clear => 'Blur 6, labels and controls only',
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.sm.copyWith(color: secondaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Floating overlay: shadow and wash allowed here.',
              style: theme.typography.body.xs.copyWith(color: secondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelsStory extends StatelessWidget {
  const _PanelsStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 460,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _GlassContentList()),
              for (final (index, variant) in GlassVariant.values.indexed)
                _FloatingGlassPanel(variant: variant, top: 10 + index * 110),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Scroll the list under the panels. One blur per surface, tight '
          'clip, and glass never sits inside glass.',
        ),
      ],
    );
  }
}

class _DockStory extends StatelessWidget {
  const _DockStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 430,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _GlassContentList()),
              // The reading dock: the active entry reads pressed (foreground
              // at 10%) and groups part on a hairline, like the brand's
              // storybook reading dock.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 96,
                child: Center(
                  child: GlassDock(
                    actions: <GlassDockEntry>[
                      GlassDockAction(
                        icon: FLucideIcons.listTree,
                        label: 'Contents',
                        semanticLabel: 'Contents',
                        pressed: true,
                        onPressed: _noop,
                      ),
                      GlassDockAction(
                        icon: FLucideIcons.link,
                        label: 'Copy link',
                        semanticLabel: 'Copy link',
                        onPressed: _noop,
                      ),
                      GlassDockAction(
                        icon: FLucideIcons.share,
                        label: 'Share',
                        semanticLabel: 'Share',
                        onPressed: _noop,
                      ),
                      GlassDockSeparator(),
                      GlassDockAction(
                        icon: FLucideIcons.arrowUp,
                        label: 'Back to top',
                        semanticLabel: 'Back to top',
                        onPressed: _noop,
                      ),
                    ],
                  ),
                ),
              ),
              // The selection dock: lead words, then a hairline, then the
              // groups, then the one main action set apart.
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: GlassDock(
                    lead: const Text('3 selected'),
                    actions: const <GlassDockEntry>[
                      GlassDockAction(
                        icon: FLucideIcons.archive,
                        label: 'Archive',
                        semanticLabel: 'Archive',
                        onPressed: _noop,
                      ),
                      GlassDockAction(
                        icon: FLucideIcons.folderInput,
                        label: 'Move',
                        semanticLabel: 'Move',
                        onPressed: _noop,
                      ),
                      GlassDockAction(
                        icon: FLucideIcons.trash2,
                        label: 'Delete',
                        semanticLabel: 'Delete',
                        onPressed: _noop,
                      ),
                    ],
                    action: FButton(
                      size: .sm,
                      onPress: () {},
                      // The web story's `Button size="sm" class="rounded-full"`:
                      // one pill main action at the end.
                      style: _pillActionStyle(theme),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'A pill of entries over the page: pressed reads foreground at 10%, '
          'hover 8%, groups part on a hairline, and the one main action sits '
          'behind a hairline at the end. Hover and focus change color only; '
          'the disabled control reads at half strength.',
        ),
      ],
    );
  }
}

void _noop() {}

/// The web story's action button (`Button size="sm" class="rounded-full"`):
/// the theme's sm style with every state's shape re-pinned to a full pill,
/// the way the theme factory re-pins button shapes without losing the
/// per-state colors.
FButtonStyle _pillActionStyle(FThemeData theme) {
  final style = theme.buttonStyles.primary.sm;
  ShapeDecoration pill(Decoration decoration) {
    final shapeDecoration = decoration as ShapeDecoration;
    final border = shapeDecoration.shape as RoundedSuperellipseBorder;
    return ShapeDecoration(
      color: shapeDecoration.color,
      image: shapeDecoration.image,
      gradient: shapeDecoration.gradient,
      shadows: shapeDecoration.shadows,
      shape: border.copyWith(borderRadius: BorderRadius.circular(100)),
    );
  }

  return FButtonStyle(
    decoration: FVariants.raw(pill(style.decoration.base), <FTappableVariantConstraint, Decoration>{
      for (final MapEntry(key: constraint, :value) in style.decoration.variants.entries)
        constraint: pill(value),
    }),
    contentStyle: style.contentStyle,
    iconContentStyle: style.iconContentStyle,
    tappableStyle: style.tappableStyle,
    focusedOutlineStyle: style.focusedOutlineStyle,
  );
}

class _GrainStory extends StatefulWidget {
  const _GrainStory();

  @override
  State<_GrainStory> createState() => _GrainStoryState();
}

class _GrainStoryState extends State<_GrainStory> {
  bool _grain = true;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FSwitch(
          value: _grain,
          label: const Text('Grain'),
          description: const Text('A seeded, static noise tile under the panel content.'),
          onChange: (value) => setState(() => _grain = value),
        ),
        SizedBox(height: context.spacing.lg),
        SizedBox(
          height: 260,
          child: Stack(
            children: <Widget>[
              // A material gives the grain something textured to sit on.
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: theme.style.borderRadius.lg,
                  child: BrandMaterialSurface(recipe: brandMaterialById('copper-sweep')!),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: GlassPanel(
                  grain: _grain,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Frosted panel',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _grain
                            ? 'Grain is on: one 160px noise tile, painted once, never animated.'
                            : 'Grain is off: only the wash, the edge and the shine.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Every panel shares one seed, so grainy panels read as one material.',
        ),
      ],
    );
  }
}

class _FallbackStory extends StatelessWidget {
  const _FallbackStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 300,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final halfWidth = (constraints.maxWidth - 48) / 2;
              return Stack(
                children: <Widget>[
                  const Positioned.fill(child: _GlassContentList()),
                  Positioned(
                    top: 48,
                    left: 16,
                    width: halfWidth,
                    child: GlassPanel(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Glass',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'One blur, 1.5x saturation, a 64% wash.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 48,
                    right: 16,
                    width: halfWidth,
                    child: GlassPanel(
                      fallback: true,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Solid fallback',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Card fill, same border and shine, no blur layer.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Reduced transparency gets the solid card: honest, readable, and '
          'still unmistakably glass by its border and shine.',
        ),
      ],
    );
  }
}

class _LiquidStory extends StatelessWidget {
  const _LiquidStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final supported = ui.ImageFilter.isShaderFilterSupported;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 380,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _GlassContentList()),
              const Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: LiquidGlass(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Liquid glass',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'The backdrop bends at the rim: refraction, dispersion, '
                        'and the bright edge, from one fragment shader.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 150,
                left: 16,
                right: 16,
                child: LiquidGlass(
                  fallback: true,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Fallback',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solid card, same edge work, no refraction layer.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        _Caption(
          supported
              ? 'ImageFilter.shader needs Impeller; this renderer supports it, '
                    'so the top pane refracts. The engine writes the texture size '
                    'and the backdrop; the widget only sets the lens.'
              : 'ImageFilter.shader needs Impeller; this renderer cannot, so '
                    'the top pane frosts — blur 11 and 1.5x saturation, the '
                    "web kit's non-Chromium fallback — while the marked pane "
                    'takes the solid card.',
        ),
      ],
    );
  }
}

/// The brand's signature pairing (glass.stories.svelte "over a shader"):
/// a full-bleed copper material stays the picture while a smoke grain panel
/// borrows its color for the reading surface.
class _GlassOverMaterialStory extends StatelessWidget {
  const _GlassOverMaterialStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 460,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: BrandMaterialSurface(recipe: brandMaterialById('copper-sweep')!),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: GlassPanel(
                    variant: GlassVariant.smoke,
                    grain: true,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'Copper, through frosted glass.',
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'The material stays the picture. The panel only '
                          'borrows its color, so the reading surface never '
                          'has an edge in it.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.625,
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Smoke over copper-sweep, exactly as the brand story stages it: '
          'the material keeps its edges, the panel keeps none.',
        ),
      ],
    );
  }
}

/// The liquid story's own composition (liquid-glass.stories.svelte): a
/// circular lens and a formatting dock floating over etched silk.
class _LiquidOverMaterialStory extends StatelessWidget {
  const _LiquidOverMaterialStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 460,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: BrandMaterialSurface(recipe: brandMaterialById('etched-silk')!),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // The lens: size-44 (176dp) rounded-full, bend 60 / edge
                    // 26 in the kit's own units — here refraction 30 (the
                    // port's displacement is bend/2) with the same edge.
                    SizedBox(
                      width: 176,
                      height: 176,
                      child: LiquidGlass(
                        radius: BorderRadius.circular(88),
                        refraction: 30,
                        edgeWidth: 26,
                        padding: EdgeInsets.zero,
                        child: const Center(
                          child: Text(
                            'A lens',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40), // the story's gap-10
                    LiquidGlass(
                      radius: BorderRadius.circular(24),
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: <Widget>[
                          for (final icon in <IconData>[
                            FLucideIcons.bold,
                            FLucideIcons.italic,
                            FLucideIcons.link,
                            FLucideIcons.list,
                          ])
                            _LiquidToolbarButton(icon: icon),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Etched silk under a liquid lens and a formatting dock. On '
          'renderers without Impeller the liquid takes its honest solid '
          'path — the composition is the point.',
        ),
      ],
    );
  }
}

/// One 36dp round icon control inside the liquid formatting dock (the
/// story's size-9 rounded-full buttons, hover foreground at 10%).
class _LiquidToolbarButton extends StatefulWidget {
  const _LiquidToolbarButton({required this.icon});

  final IconData icon;

  @override
  State<_LiquidToolbarButton> createState() => _LiquidToolbarButtonState();
}

class _LiquidToolbarButtonState extends State<_LiquidToolbarButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: _noop,
          child: Tooltip(
            excludeFromSemantics: true,
            message: switch (widget.icon) {
              FLucideIcons.bold => 'Bold',
              FLucideIcons.italic => 'Italic',
              FLucideIcons.link => 'Link',
              _ => 'List',
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovering ? theme.colors.foreground.withValues(alpha: 0.10) : null,
              ),
              child: Icon(widget.icon, size: 16, color: theme.colors.foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Rings behind glass." (glass.stories.svelte): hero rings seeded with a
/// name bleed off the right edge while a frost panel floats at the left.
class _RingsBehindGlassStory extends StatelessWidget {
  const _RingsBehindGlassStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 460,
          child: Stack(
            children: <Widget>[
              const Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 500,
                child: Center(child: BrandRings(seed: 'glass')),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Rings behind glass.',
                            style: TextStyle(
                              fontSize: 24,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.72,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Where the panel crosses the rings they soften '
                            'into it, like looking through a window.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.625,
                              color: context.theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Hero rings seeded with "glass" — the same name always draws the '
          'same picture — behind a frost panel.',
        ),
      ],
    );
  }
}

class _HeroStory extends StatefulWidget {
  const _HeroStory();

  @override
  State<_HeroStory> createState() => _HeroStoryState();
}

class _HeroStoryState extends State<_HeroStory> {
  String _name = 'starter';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FTextField(
          label: const Text('Name the rings are drawn from'),
          control: .managed(
            onChange: (value) => setState(() => _name = value.text),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        BrandRings(
          seed: _name.trim().isEmpty ? 'starter' : _name.trim(),
          motion: RingMotion.rippleTurn,
          semanticsLabel: 'Hero rings for ${_name.trim().isEmpty ? 'starter' : _name.trim()}',
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The seed drives every gap, turn and the accent ring, so the same '
          'name always draws the same picture. Reduced motion gets the still '
          'frame.',
        ),
      ],
    );
  }
}

class _CornerStory extends StatelessWidget {
  const _CornerStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _CornerCard(
                title: 'Flux',
                body: 'A tiny state library for screens that mostly read data.',
                seed: 'Flux',
                // Library blue (BRAND.md s7: one color per kind, everywhere).
                accent: brand.blue,
              ),
            ),
            SizedBox(width: context.spacing.lg),
            Expanded(
              child: _CornerCard(
                title: 'Cadence',
                body: 'A build runner for the slow parts of a release.',
                seed: 'Cadence',
                // Command-line tool teal (BRAND.md s7).
                accent: brand.teal,
                quiet: true,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The rings sit first in the card stack and the content above them: '
          'rings never render behind text.',
        ),
      ],
    );
  }
}

class _CornerCard extends StatelessWidget {
  const _CornerCard({
    required this.title,
    required this.body,
    required this.seed,
    required this.accent,
    this.quiet = false,
  });

  final String title;
  final String body;
  final String seed;
  final Color accent;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      // The rings take their own row at the top-right and the text flows
      // under them, so the card never overflows and rings never render
      // behind text.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: CornerRings(seed: seed, accentColor: accent, quiet: quiet, size: 84),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            title,
            style: theme.typography.body.lg.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            body,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _BandStory extends StatelessWidget {
  const _BandStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox.square(
          dimension: 300,
          child: Stack(
            children: <Widget>[
              // Bleeding off the right edge, like a closing band.
              Positioned(
                right: -60,
                top: -50,
                child: BandArcs(accentColor: theme.colors.primary),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The same arcs on every site, no seed. On the orange band the '
          'accent passes the on-orange color so ring 3 reads dark.',
        ),
      ],
    );
  }
}

class _HorizonStory extends StatelessWidget {
  const _HorizonStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionTitle(title: 'Awake'),
        SizedBox(height: context.spacing.sm),
        const HorizonRings(seed: 'starter', ripple: true, semanticsLabel: 'Awake horizon rings'),
        SizedBox(height: context.spacing.lg),
        const _SectionTitle(title: 'Asleep'),
        SizedBox(height: context.spacing.sm),
        const HorizonRings(seed: 'starter', awake: false, semanticsLabel: 'Asleep horizon rings'),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The awake switch fades the sun and stars over 0.8s; the ripple '
          'runs light out through the rings every few seconds. Reduced '
          'motion stills both.',
        ),
      ],
    );
  }
}

class _IndicatorStory extends StatelessWidget {
  const _IndicatorStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: context.spacing.xl,
          runSpacing: context.spacing.lg,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: const <Widget>[
            _Indicator(
              label: 'Loader 24',
              child: RingLoader(semanticsLabel: 'Loading'),
            ),
            _Indicator(
              label: 'Loader 40',
              child: RingLoader(size: 40, semanticsLabel: 'Loading'),
            ),
            _Indicator(
              label: 'Status off',
              child: StatusRing(active: false),
            ),
            _Indicator(
              label: 'Status on',
              child: StatusRing(active: true),
            ),
            _Indicator(
              label: 'Status stale',
              child: StatusRing(active: false, stale: true),
            ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const RingMeter(
          label: 'Usage this month',
          items: <RingMeterItem>[
            RingMeterItem(label: 'Storage', value: 0.72, detail: '7.2 of 10 GB'),
            RingMeterItem(label: 'Build minutes', value: 0.4, detail: '1,200 of 3,000'),
            RingMeterItem(label: 'Bandwidth', value: 0.18, detail: '18 of 100 GB'),
          ],
          semanticsLabel: 'Usage this month',
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The meter stacks the shares as rings inside rings, the first in '
          'orange; the loader sweeps its three arcs; the status ring turns '
          'when the thing is on, breaks when it is stale, and rests faint '
          'otherwise.',
        ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        child,
        SizedBox(height: context.spacing.sm),
        _Caption(label),
      ],
    );
  }
}

class _DividerStory extends StatelessWidget {
  const _DividerStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const RingDivider(label: 'Part two'),
        SizedBox(height: context.spacing.sm),
        const _Caption(
          'A seeded three-ring cluster drawn from the name; the accent dot '
          'rides the accent ring.',
        ),
        SizedBox(height: context.spacing.lg),
        const RingDivider(filled: true, seed: 'done'),
        SizedBox(height: context.spacing.sm),
        const _Caption(
          'The dot fills only when the divider marks something done, open '
          'or selected.',
        ),
      ],
    );
  }
}

class _MotionStory extends StatefulWidget {
  const _MotionStory();

  @override
  State<_MotionStory> createState() => _MotionStoryState();
}

class _MotionStoryState extends State<_MotionStory> {
  static const _presetNames = <String>['still', 'turn', 'ripple'];

  String _preset = 'turn';
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppSegmented<String>(
          options: <AppSegmentOption<String>>[
            for (final name in _presetNames) (value: name, label: name, key: null),
          ],
          value: _preset,
          onChanged: (value) => setState(() => _preset = value),
        ),
        SizedBox(height: context.spacing.lg),
        FSwitch(
          value: _paused,
          label: const Text('Pause'),
          description: const Text('Pausing holds the rings where they are.'),
          onChange: (value) => setState(() => _paused = value),
        ),
        SizedBox(height: context.spacing.lg),
        Center(
          child: BrandRings(
            seed: 'starter',
            motion: RingMotion.presets[_preset] ?? RingMotion.still,
            paused: _paused,
            semanticsLabel: 'Hero rings with the $_preset motion',
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Only the rings a motion marks actually move, and the movement '
          'stops off screen. Reduced motion always gets the still picture.',
        ),
      ],
    );
  }
}
