import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_material_text.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/fx/shaders/brand_shimmer.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';
import 'package:starter/shared/widgets/marks/material_bar.dart';
import 'package:starter/shared/widgets/marks/material_card.dart';
import 'package:starter/shared/widgets/marks/material_frame.dart';
import 'package:starter/shared/widgets/marks/material_gauge.dart';
import 'package:starter/shared/widgets/marks/material_rings.dart';
import 'package:starter/shared/widgets/marks/material_rule.dart';
import 'package:starter/shared/widgets/marks/material_slider.dart';
import 'package:starter/shared/widgets/marks/material_sparkline.dart';
import 'package:starter/shared/widgets/marks/material_stage.dart';
import 'package:starter/shared/widgets/marks/material_tabs.dart';
import 'package:starter/shared/widgets/marks/material_tag.dart';
import 'package:starter/shared/widgets/marks/material_tile.dart';

/// The brand-material stories: all sixteen approved materials, the seeded
/// picker, material text, the wordmark shimmer, the pause contract and the
/// composed material variants, each in its own dev-gallery screen (BRAND.md
/// s7 "Materials").
///
/// Dev-only surface, so the labels and copy are literal English.
enum BrandMaterialGalleryKind {
  swatches,
  seeded,
  text,
  shimmer,
  pause,
  variants,
  tiles,
  surfaces,
}

/// Builds the "Brand materials" gallery cases, one per material capability.
List<GalleryCase> buildBrandMaterialGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandMaterialGalleryKind.values)
      TypedGalleryCase<BrandMaterialGalleryKind>(
        id: 'brandMaterial.${kind.name}',
        screenId: 'brandMaterial',
        screenLabelBuilder: (_) => 'Brand materials',
        caseLabelBuilder: (_) => _caseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _BrandMaterialPreview(kind: state),
      ),
  ];
}

String _caseLabel(BrandMaterialGalleryKind kind) => switch (kind) {
  BrandMaterialGalleryKind.swatches => 'The sixteen materials',
  BrandMaterialGalleryKind.seeded => 'Seeded picker',
  BrandMaterialGalleryKind.text => 'Material text',
  BrandMaterialGalleryKind.shimmer => 'Wordmark shimmer',
  BrandMaterialGalleryKind.pause => 'Pause control',
  BrandMaterialGalleryKind.variants => 'Material variants',
  BrandMaterialGalleryKind.tiles => 'Material tiles',
  BrandMaterialGalleryKind.surfaces => 'Material surfaces',
};

String _caseDescription(BrandMaterialGalleryKind kind) => switch (kind) {
  BrandMaterialGalleryKind.swatches =>
    'Every approved look, drawn by the live shader. Nothing else may ship a material.',
  BrandMaterialGalleryKind.seeded => 'The same name always picks the same material.',
  BrandMaterialGalleryKind.text => 'Letters as a mask over a live material frame.',
  BrandMaterialGalleryKind.tiles =>
    'A small framed swatch, in either shape, with or without a child.',
  BrandMaterialGalleryKind.shimmer => 'One shine band sweeps the letters, then rests.',
  BrandMaterialGalleryKind.pause =>
    'Paused holds the current frame; reduced motion stops on its own.',
  BrandMaterialGalleryKind.variants =>
    'Bar, sparkline, gauge, rings, tag and rule: material as the finish.',
  BrandMaterialGalleryKind.surfaces =>
    'Card, frame, stage, tabs and slider: material as the surface.',
};

class _BrandMaterialPreview extends ConsumerWidget {
  const _BrandMaterialPreview({required this.kind});

  final BrandMaterialGalleryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    // The brand's own primary is oxide orange (BRAND.md s4: --primary points
    // at --orange), so the showcase pins the brand accent no matter which
    // accent the gallery environment picked; otherwise the material text's
    // tint target and the shimmer's surroundings read in a neutral accent.
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
            _CaseHeader(title: _caseLabel(kind), description: _caseDescription(kind)),
            SizedBox(height: context.spacing.xl),
            switch (kind) {
              BrandMaterialGalleryKind.swatches => const _SwatchStory(),
              BrandMaterialGalleryKind.seeded => const _SeededStory(),
              BrandMaterialGalleryKind.text => const _TextStory(),
              BrandMaterialGalleryKind.tiles => const _MaterialTilesStory(),
              BrandMaterialGalleryKind.shimmer => const _ShimmerStory(),
              BrandMaterialGalleryKind.pause => const _PauseStory(),
              BrandMaterialGalleryKind.variants => const _VariantsStory(),
              BrandMaterialGalleryKind.surfaces => const _SurfacesStory(),
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

/// Token names and ids are machine values, so they run in JetBrains Mono
/// (BRAND.md s5: mono never sets headings or labels people read).
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

class _SwatchStory extends StatelessWidget {
  const _SwatchStory();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.spacing.lg,
      runSpacing: context.spacing.lg,
      children: <Widget>[
        for (final material in brandMaterials)
          _MaterialSwatchCard(
            recipe: material,
            name: material.name,
            id: material.id,
          ),
      ],
    );
  }
}

/// A labelled swatch card: the live material quad, its human name, its id.
///
/// The card itself is outline-only; the material fills the quad, never the
/// card behind text (BRAND.md s13).
class _MaterialSwatchCard extends StatelessWidget {
  const _MaterialSwatchCard({
    required this.recipe,
    required this.name,
    required this.id,
    this.extent = 120,
  });

  final BrandMaterialRecipe recipe;
  final String name;
  final String id;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: theme.style.borderRadius.lg,
          child: SizedBox.square(
            dimension: extent,
            child: BrandMaterialSurface(recipe: recipe),
          ),
        ),
        SizedBox(height: context.spacing.sm),
        SizedBox(
          width: extent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _MonoText(id),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeededStory extends StatelessWidget {
  const _SeededStory();

  @override
  Widget build(BuildContext context) {
    const names = <String>['starter', 'hmziq', 'gallery', 'shell'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: context.spacing.lg,
          runSpacing: context.spacing.lg,
          children: <Widget>[
            for (final name in names)
              _MaterialSwatchCard(
                recipe: materialFor(name),
                name: 'materialFor("$name")',
                id: materialFor(name).id,
                extent: 96,
              ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The picker hashes the name, so a given project always lands on the '
          'same look. Callers never choose by eye.',
        ),
      ],
    );
  }
}

class _MaterialTilesStory extends StatelessWidget {
  const _MaterialTilesStory();

  @override
  Widget build(BuildContext context) {
    final recipe = brandMaterialById('hammered-copper')!;
    return Wrap(
      spacing: context.spacing.lg,
      runSpacing: context.spacing.lg,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        MaterialTile(recipe: recipe),
        MaterialTile(recipe: recipe, shape: MaterialTileShape.circle),
        MaterialTile(recipe: brandMaterialById('liquid-chrome')!, size: 48),
      ],
    );
  }
}

class _TextStory extends StatelessWidget {
  const _TextStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionTitle(title: 'Copper sweep'),
        SizedBox(height: context.spacing.sm),
        const BrandMaterialText(text: 'starter'),
        SizedBox(height: context.spacing.lg),
        const _SectionTitle(title: 'Liquid chrome'),
        SizedBox(height: context.spacing.sm),
        const BrandMaterialText(text: 'hmziq', materialId: 'liquid-chrome', fontSize: 40),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The text raster masks a live material frame. Only display-size '
          'headings wear a material; body text stays flat.',
        ),
      ],
    );
  }
}

class _ShimmerStory extends StatelessWidget {
  const _ShimmerStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const BrandShimmer(child: AppWordmark(name: 'starter')),
        SizedBox(height: context.spacing.xs),
        const _Caption('The wordmark, swept once per cycle.'),
        SizedBox(height: context.spacing.lg),
        const BrandShimmer(
          once: true,
          child: Text(
            'Changelog',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, height: 1.1),
          ),
        ),
        SizedBox(height: context.spacing.xs),
        const _Caption(
          'One sweep and it rests. Reduced motion never shows the band at all.',
        ),
      ],
    );
  }
}

class _PauseStory extends StatefulWidget {
  const _PauseStory();

  @override
  State<_PauseStory> createState() => _PauseStoryState();
}

class _PauseStoryState extends State<_PauseStory> {
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FSwitch(
          value: _paused,
          label: const Text('Hold the frame'),
          description: const Text('Paused materials freeze where they are and keep their shader.'),
          onChange: (value) => setState(() => _paused = value),
        ),
        SizedBox(height: context.spacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: theme.style.borderRadius.lg,
              child: SizedBox.square(
                dimension: 132,
                child: BrandMaterialSurface(recipe: brandMaterials.first, paused: _paused),
              ),
            ),
            SizedBox(width: context.spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  BrandMaterialText(text: 'starter', fontSize: 32, paused: _paused),
                  SizedBox(height: context.spacing.sm),
                  const _Caption(
                    'The ambient-art contract: paused holds the current frame, '
                    'and reduced motion stops the drift without asking.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The material the variant specimens share.
final BrandMaterialRecipe _variantMaterial = brandMaterialById('copper-sweep')!;

class _VariantsStory extends StatelessWidget {
  const _VariantsStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionTitle(title: 'Bar'),
        SizedBox(height: context.spacing.sm),
        MaterialBar(recipe: _variantMaterial, value: 0.68),
        SizedBox(height: context.spacing.lg),
        const _SectionTitle(title: 'Sparkline'),
        SizedBox(height: context.spacing.sm),
        MaterialSparkline(
          recipe: _variantMaterial,
          points: const <double>[0.2, 0.35, 0.3, 0.55, 0.5, 0.75, 0.9],
        ),
        SizedBox(height: context.spacing.lg),
        const _SectionTitle(title: 'Gauge and rings'),
        SizedBox(height: context.spacing.sm),
        // A Wrap, so the trio reflows at any gallery width.
        Wrap(
          spacing: context.spacing.xl,
          runSpacing: context.spacing.lg,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            MaterialGauge(recipe: _variantMaterial, value: 0.68),
            // The rings picture keeps the hero recipe's 520x440 box, so it
            // gets a fixed width inside the Wrap.
            SizedBox(
              width: 260,
              child: MaterialRings(recipe: _variantMaterial, seed: 'starter'),
            ),
            MaterialTag(recipe: _variantMaterial, label: 'Seeded build'),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _SectionTitle(title: 'Rule'),
        SizedBox(height: context.spacing.sm),
        MaterialRule(recipe: _variantMaterial),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The material fills the piece — the bar, the area under the curve, '
          'the swept arc, the ring strokes — and never the page around it.',
        ),
      ],
    );
  }
}

/// A second approved look so the surfaces story shows the material moving
/// between placements.
final BrandMaterialRecipe _surfaceMaterial = brandMaterialById('liquid-chrome')!;

class _SurfacesStory extends StatefulWidget {
  const _SurfacesStory();

  @override
  State<_SurfacesStory> createState() => _SurfacesStoryState();
}

class _SurfacesStoryState extends State<_SurfacesStory> {
  int _tab = 1;

  double _slider = 0.4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MaterialTabs(
          recipe: _variantMaterial,
          tabs: const <String>['Builds', 'Releases', 'Usage'],
          selectedIndex: _tab,
          onSelected: (index) => setState(() => _tab = index),
        ),
        SizedBox(height: context.spacing.lg),
        MaterialSlider(
          recipe: _variantMaterial,
          value: _slider,
          onChanged: (value) => setState(() => _slider = value),
          semanticLabel: 'Material slider',
        ),
        SizedBox(height: context.spacing.lg),
        MaterialStage(
          recipe: _surfaceMaterial,
          title: 'starter',
          child: Center(
            child: Text(
              'starter',
              style: context.theme.typography.display.xl.copyWith(
                color: context.theme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        MaterialCard(
          recipe: _surfaceMaterial,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Crowned card',
                style: context.theme.typography.body.md.copyWith(
                  color: context.theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: context.spacing.xs),
              Text(
                'The material lives in the band; the body keeps the outline.',
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        MaterialFrame(
          recipe: _variantMaterial,
          child: Text(
            'Copper sweep, 6px band — the one plan that leads the row.',
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The material draws edges only — the tag pill, the tab rule, the '
          'frame band — and words always sit on the page color.',
        ),
      ],
    );
  }
}
