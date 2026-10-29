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
enum BrandGlassGalleryKind { panels, dock, grain, fallback, liquid }

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
};

String _glassCaseDescription(BrandGlassGalleryKind kind) => switch (kind) {
  BrandGlassGalleryKind.panels =>
    'Frost, smoke, tint and clear floating over a scrolling list. Glass carries one blur and never nests.',
  BrandGlassGalleryKind.dock =>
    'A floating pill of icon controls. Every icon-only control announces what it does.',
  BrandGlassGalleryKind.grain => 'The seeded grain overlay behind the panel content.',
  BrandGlassGalleryKind.fallback =>
    'The honest degraded path: solid card fill, same border, no blur layer.',
  BrandGlassGalleryKind.liquid =>
    'Backdrop refraction through a fragment shader; solid card where the engine cannot.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 360,
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _GlassContentList()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: GlassDock(
                    actions: <GlassDockAction>[
                      GlassDockAction(
                        icon: FLucideIcons.skipBack,
                        semanticLabel: 'Previous track',
                        onPressed: () {},
                      ),
                      GlassDockAction(
                        icon: FLucideIcons.play,
                        semanticLabel: 'Play',
                        onPressed: () {},
                      ),
                      const GlassDockAction(
                        icon: FLucideIcons.pause,
                        semanticLabel: 'Pause',
                      ),
                      GlassDockAction(
                        icon: FLucideIcons.skipForward,
                        semanticLabel: 'Next track',
                        onPressed: () {},
                      ),
                      GlassDockAction(
                        icon: FLucideIcons.volume2,
                        semanticLabel: 'Mute',
                        onPressed: () {},
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
          'A pill of icon controls over the page. Hover and focus change '
          'color only; the disabled control reads at half strength.',
        ),
      ],
    );
  }
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
                    'both panes take the solid path — the honest degraded glass.',
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
              label: 'Loader 36',
              child: RingLoader(size: 36, strokeWidth: 3, semanticsLabel: 'Loading'),
            ),
            _Indicator(
              label: 'Meter 68%',
              child: RingMeter(value: 0.68, size: 48, semanticsLabel: '68 percent'),
            ),
            _Indicator(
              label: 'Meter 30%',
              child: RingMeter(value: 0.3, size: 48, semanticsLabel: '30 percent'),
            ),
            _Indicator(
              label: 'Status off',
              child: StatusRing(active: false),
            ),
            _Indicator(
              label: 'Status on',
              child: StatusRing(active: true),
            ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The accent arc sweeps the loader; the meter draws a value on a '
          'track; the status ring fills only when the thing is on.',
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
        const RingDivider(),
        SizedBox(height: context.spacing.sm),
        const _Caption('Hollow at rest, between sections.'),
        SizedBox(height: context.spacing.lg),
        const RingDivider(filled: true),
        SizedBox(height: context.spacing.sm),
        const _Caption(
          'Filled only when the divider marks something done, open or '
          'selected.',
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
            for (final name in _presetNames) (value: name, label: name),
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
