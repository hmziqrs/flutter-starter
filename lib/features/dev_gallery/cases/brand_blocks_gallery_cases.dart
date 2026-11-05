import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/blocks/before_after.dart';
import 'package:starter/shared/widgets/blocks/big_numbers.dart';
import 'package:starter/shared/widgets/blocks/bullets.dart';
import 'package:starter/shared/widgets/blocks/check_list.dart';
import 'package:starter/shared/widgets/blocks/code_block.dart';
import 'package:starter/shared/widgets/blocks/code_lines.dart';
import 'package:starter/shared/widgets/blocks/command_bar.dart';
import 'package:starter/shared/widgets/blocks/command_box.dart';
import 'package:starter/shared/widgets/blocks/command_palette.dart';
import 'package:starter/shared/widgets/blocks/data_table.dart';
import 'package:starter/shared/widgets/blocks/detail_list.dart';
import 'package:starter/shared/widgets/blocks/detail_section.dart';
import 'package:starter/shared/widgets/blocks/endpoint_card.dart';
import 'package:starter/shared/widgets/blocks/eyebrow.dart';
import 'package:starter/shared/widgets/blocks/inline_code.dart';
import 'package:starter/shared/widgets/blocks/line_tabs.dart';
import 'package:starter/shared/widgets/blocks/metric_trend.dart';
import 'package:starter/shared/widgets/blocks/page_intro.dart';
import 'package:starter/shared/widgets/blocks/person_card.dart';
import 'package:starter/shared/widgets/blocks/question.dart';
import 'package:starter/shared/widgets/blocks/release_card.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';
import 'package:starter/shared/widgets/blocks/stat_card.dart';
import 'package:starter/shared/widgets/blocks/stat_grid.dart';
import 'package:starter/shared/widgets/blocks/step_number.dart';
import 'package:starter/shared/widgets/blocks/stepper.dart';
import 'package:starter/shared/widgets/blocks/summary_box.dart';
import 'package:starter/shared/widgets/blocks/terminal_window.dart';
import 'package:starter/shared/widgets/blocks/toc.dart';
import 'package:starter/shared/widgets/blocks/usage_meter.dart';
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';
import 'package:starter/shared/widgets/marks/app_mark.dart';
import 'package:starter/shared/widgets/marks/band_surface.dart';
import 'package:starter/shared/widgets/marks/bento_tile.dart';
import 'package:starter/shared/widgets/marks/brand_icon.dart';
import 'package:starter/shared/widgets/marks/cta_band.dart';
import 'package:starter/shared/widgets/marks/element_card.dart';
import 'package:starter/shared/widgets/marks/logo_square.dart';
import 'package:starter/shared/widgets/marks/signature_footer.dart';
import 'package:starter/shared/widgets/marks/simple_icons.dart';

/// The marks-and-bands stories (the quads kit, BRAND.md s7): the mark and
/// logo square, bento tiles, element cards, the orange band, the gray band,
/// the signature footer and the third-party marks. Dev-only surface, so the
/// labels are literal English.
enum BrandMarksGalleryKind { marks, bento, elements, ctaBand, grayBand, footer, brandIcons }

/// Builds the "Marks & bands" gallery cases, one per signature piece.
List<GalleryCase> buildBrandMarksGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandMarksGalleryKind.values)
      TypedGalleryCase<BrandMarksGalleryKind>(
        id: 'brandMarks.${kind.name}',
        screenId: 'brandMarks',
        screenLabelBuilder: (_) => 'Marks & bands',
        caseLabelBuilder: (_) => _marksCaseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _BrandMarksPreview(kind: state),
      ),
  ];
}

String _marksCaseLabel(BrandMarksGalleryKind kind) => switch (kind) {
  BrandMarksGalleryKind.marks => 'Mark and logo square',
  BrandMarksGalleryKind.bento => 'Bento tiles',
  BrandMarksGalleryKind.elements => 'Element cards',
  BrandMarksGalleryKind.ctaBand => 'Orange band',
  BrandMarksGalleryKind.grayBand => 'Gray band',
  BrandMarksGalleryKind.footer => 'Signature footer',
  BrandMarksGalleryKind.brandIcons => 'Third-party marks',
};

String _marksCaseDescription(BrandMarksGalleryKind kind) => switch (kind) {
  BrandMarksGalleryKind.marks =>
    'The two-letter mark scales from its size; the square ends a wordmark.',
  BrandMarksGalleryKind.bento => 'Outline tiles for grids: a thin line, no fill, no shadow.',
  BrandMarksGalleryKind.elements =>
    'Project cards with a corner-rings fingerprint in the kind color.',
  BrandMarksGalleryKind.ctaBand =>
    'The only solid orange section on a screen, at most one per screen.',
  BrandMarksGalleryKind.grayBand => 'The quiet neutral band for numbers or a group of cards.',
  BrandMarksGalleryKind.footer =>
    'The name at wordmark weight spanning the container, square at the end.',
  BrandMarksGalleryKind.brandIcons =>
    'Bundled Simple Icons glyphs; one color, never recolored or reshaped.',
};

/// The blocks stories (the blocks kit, APP-BLOCKS.md): every page-level
/// block, from the stepper to the usage meter. Dev-only surface, so the
/// labels are literal English.
enum BrandBlocksGalleryKind {
  stepper,
  segmented,
  questions,
  code,
  commands,
  terminal,
  table,
  summary,
  lists,
  detailSection,
  numbers,
  stats,
  usage,
  beforeAfter,
  pageIntro,
  people,
  releases,
  endpoints,
  toc,
  lineTabs,
  eyebrow,
}

/// Builds the "Blocks" gallery cases, one per block family.
List<GalleryCase> buildBrandBlocksGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandBlocksGalleryKind.values)
      TypedGalleryCase<BrandBlocksGalleryKind>(
        id: 'brandBlocks.${kind.name}',
        screenId: 'brandBlocks',
        screenLabelBuilder: (_) => 'Blocks',
        caseLabelBuilder: (_) => _blocksCaseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _BrandBlocksPreview(kind: state),
      ),
  ];
}

String _blocksCaseLabel(BrandBlocksGalleryKind kind) => switch (kind) {
  BrandBlocksGalleryKind.stepper => 'Stepper',
  BrandBlocksGalleryKind.segmented => 'Segmented control',
  BrandBlocksGalleryKind.questions => 'Questions',
  BrandBlocksGalleryKind.code => 'Code and command',
  BrandBlocksGalleryKind.commands => 'Command box and palette',
  BrandBlocksGalleryKind.terminal => 'Terminal window',
  BrandBlocksGalleryKind.table => 'Data table',
  BrandBlocksGalleryKind.summary => 'Summary box',
  BrandBlocksGalleryKind.lists => 'Bullets and checklist',
  BrandBlocksGalleryKind.detailSection => 'Detail section',
  BrandBlocksGalleryKind.numbers => 'Big numbers and trends',
  BrandBlocksGalleryKind.stats => 'Stat grid',
  BrandBlocksGalleryKind.usage => 'Usage meter',
  BrandBlocksGalleryKind.beforeAfter => 'Before and after',
  BrandBlocksGalleryKind.pageIntro => 'Page intro',
  BrandBlocksGalleryKind.people => 'Person card',
  BrandBlocksGalleryKind.releases => 'Release card',
  BrandBlocksGalleryKind.endpoints => 'Endpoint card',
  BrandBlocksGalleryKind.toc => 'Table of contents',
  BrandBlocksGalleryKind.lineTabs => 'Line tabs',
  BrandBlocksGalleryKind.eyebrow => 'Eyebrow',
};

String _blocksCaseDescription(BrandBlocksGalleryKind kind) => switch (kind) {
  BrandBlocksGalleryKind.stepper =>
    'Numbered rings joined by a line; done fills, current is hollow.',
  BrandBlocksGalleryKind.segmented => 'The picked segment takes the soft primary fill.',
  BrandBlocksGalleryKind.questions => 'Details rows: the ring fills when the answer is open.',
  BrandBlocksGalleryKind.code => 'Outline code in mono, and a command that copies itself.',
  BrandBlocksGalleryKind.commands =>
    'A mono command pill with an icon copy; the palette groups a command list.',
  BrandBlocksGalleryKind.terminal => 'Always dark, on a light page too.',
  BrandBlocksGalleryKind.table => 'The column that matters sits on a soft primary wash.',
  BrandBlocksGalleryKind.summary => 'The short version at the top of a page or a legal section.',
  BrandBlocksGalleryKind.lists => 'Ring-marker bullets, and a checklist that fills when met.',
  BrandBlocksGalleryKind.detailSection => 'The titled, boxed fact group a record page repeats.',
  BrandBlocksGalleryKind.numbers => 'Huge w500 numbers, and changes colored by meaning.',
  BrandBlocksGalleryKind.stats => 'Outline cards for the numbers that matter.',
  BrandBlocksGalleryKind.usage => 'The fill changes color only when it means something.',
  BrandBlocksGalleryKind.beforeAfter => 'The manual way struck through, then the tool.',
  BrandBlocksGalleryKind.pageIntro => 'A 24 w500 title and one muted sentence.',
  BrandBlocksGalleryKind.people => 'An initial-avatar ring, the name, the role, never a photo.',
  BrandBlocksGalleryKind.releases => 'Version in mono, date and channel tag, changes as markers.',
  BrandBlocksGalleryKind.endpoints =>
    'Verb chip in its status color, path in mono; it documents, never calls.',
  BrandBlocksGalleryKind.toc => 'The current section takes the primary ring and text.',
  BrandBlocksGalleryKind.lineTabs =>
    'One row over a 1px line; the open tab takes the primary underline, counts included.',
  BrandBlocksGalleryKind.eyebrow =>
    'A small primary label over a title: a numbered ring, a rule, or ticks.',
};

class _BrandMarksPreview extends ConsumerWidget {
  const _BrandMarksPreview({required this.kind});

  final BrandMarksGalleryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    // The marks, bands and cards resolve brand tokens (on-orange, kind
    // colors, the ring hairline), so the showcase pins the oxide accent
    // (BRAND.md s4) no matter which accent the gallery environment picked.
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
              title: _marksCaseLabel(kind),
              description: _marksCaseDescription(kind),
            ),
            SizedBox(height: context.spacing.xl),
            switch (kind) {
              BrandMarksGalleryKind.marks => const _MarkStory(),
              BrandMarksGalleryKind.bento => const _BentoStory(),
              BrandMarksGalleryKind.elements => const _ElementStory(),
              BrandMarksGalleryKind.ctaBand => const _CtaBandStory(),
              BrandMarksGalleryKind.grayBand => const _GrayBandStory(),
              BrandMarksGalleryKind.footer => const _FooterStory(),
              BrandMarksGalleryKind.brandIcons => const _BrandIconStory(),
            },
          ],
        ),
      ),
    );
  }
}

class _BrandBlocksPreview extends ConsumerWidget {
  const _BrandBlocksPreview({required this.kind});

  final BrandBlocksGalleryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    // Blocks tint their picked segments, accent columns and trends with the
    // brand roles, so the showcase pins the oxide accent (BRAND.md s4) no
    // matter which accent the gallery environment picked.
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
              title: _blocksCaseLabel(kind),
              description: _blocksCaseDescription(kind),
            ),
            SizedBox(height: context.spacing.xl),
            switch (kind) {
              BrandBlocksGalleryKind.stepper => const _StepperStory(),
              BrandBlocksGalleryKind.segmented => const _SegmentedStory(),
              BrandBlocksGalleryKind.questions => const _QuestionsStory(),
              BrandBlocksGalleryKind.code => const _CodeStory(),
              BrandBlocksGalleryKind.commands => const _CommandsStory(),
              BrandBlocksGalleryKind.terminal => const _TerminalStory(),
              BrandBlocksGalleryKind.table => const _TableStory(),
              BrandBlocksGalleryKind.summary => const _SummaryStory(),
              BrandBlocksGalleryKind.lists => const _ListsStory(),
              BrandBlocksGalleryKind.detailSection => const _DetailSectionStory(),
              BrandBlocksGalleryKind.numbers => const _NumbersStory(),
              BrandBlocksGalleryKind.stats => const _StatsStory(),
              BrandBlocksGalleryKind.usage => const _UsageStory(),
              BrandBlocksGalleryKind.beforeAfter => const _BeforeAfterStory(),
              BrandBlocksGalleryKind.pageIntro => const _PageIntroStory(),
              BrandBlocksGalleryKind.people => const _PeopleStory(),
              BrandBlocksGalleryKind.releases => const _ReleasesStory(),
              BrandBlocksGalleryKind.endpoints => const _EndpointsStory(),
              BrandBlocksGalleryKind.toc => const _TocStory(),
              BrandBlocksGalleryKind.lineTabs => const _LineTabsStory(),
              BrandBlocksGalleryKind.eyebrow => const _EyebrowStory(),
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

/// Slugs and versions are machine values, so they run in JetBrains Mono
/// (BRAND.md s5: mono never sets headings or labels people read).
class _MonoText extends StatelessWidget {
  const _MonoText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.typography.body.xs.copyWith(
        color: theme.colors.mutedForeground,
        fontFamily: 'JetBrains Mono',
      ),
    );
  }
}

class _MarkStory extends StatelessWidget {
  const _MarkStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: context.spacing.lg,
          runSpacing: context.spacing.lg,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const <Widget>[
            _MarkedTile(
              mark: AppMark(symbol: 'Hq', squareLabel: 'starter mark'),
              label: '20',
            ),
            _MarkedTile(
              mark: AppMark(symbol: 'Hq', squareLabel: 'starter mark', size: 36),
              label: '36',
            ),
            _MarkedTile(
              mark: AppMark(symbol: 'Hq', squareLabel: 'starter mark', size: 56),
              label: '56',
            ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        // The square rides inline at the letters' baseline as a baseline
        // placeholder — same recipe as AppWordmark. LogoSquare reads its
        // em from the ambient DefaultTextStyle, so the span's size is
        // merged in for it.
        Builder(
          builder: (context) {
            final fontSize = theme.typography.body.lg.fontSize ?? 18;
            return Text.rich(
              TextSpan(
                text: 'starter',
                children: <InlineSpan>[
                  WidgetSpan(
                    alignment: PlaceholderAlignment.aboveBaseline,
                    baseline: TextBaseline.alphabetic,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: fontSize * 0.07),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(fontSize: fontSize),
                        child: const LogoSquare(),
                      ),
                    ),
                  ),
                ],
              ),
              style: theme.typography.body.lg.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        SizedBox(height: context.spacing.sm),
        const _Caption('The square is sized in em of the text next to it.'),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The tile is the inverse of the page: foreground tile, background '
          'letters, the bright square. No rings, no outline, no texture.',
        ),
      ],
    );
  }
}

class _MarkedTile extends StatelessWidget {
  const _MarkedTile({required this.mark, required this.label});

  final Widget mark;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        mark,
        SizedBox(height: context.spacing.sm),
        _Caption(label),
      ],
    );
  }
}

class _BentoStory extends StatelessWidget {
  const _BentoStory();

  @override
  Widget build(BuildContext context) {
    // Fixed-size tiles in a Wrap, so the grid reflows at any gallery width
    // and no tile's content overflows its square. Word tiles read like the
    // kit's bento (eyebrow, title, body at the tile's start corner); mark
    // tiles center their mark the way the wordmark story wants it.
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        BentoTile(
          size: 220,
          eyebrow: 'freeoxide',
          title: 'Free Rust tools',
          body: 'Finished before they ship, and given away.',
        ),
        BentoTile(
          size: 132,
          child: Center(
            child: AppMark(symbol: 'Hq', squareLabel: 'starter mark', size: 36),
          ),
        ),
        BentoTile(
          size: 132,
          child: Center(child: AppIconTile(icon: FLucideIcons.download)),
        ),
        BentoTile(
          size: 176,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppWordmark(name: 'starter'),
                SizedBox(height: 8),
                AppStatusTag(label: 'Shipped', role: AppStatusRole.success),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ElementStory extends StatelessWidget {
  const _ElementStory();

  @override
  Widget build(BuildContext context) {
    final brand = context.theme.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Stacked full width; each card gets a bounded height because its
        // corner-rings stack needs finite constraints.
        SizedBox(
          height: 340,
          child: ElementCard(
            number: 4,
            symbol: 'Fx',
            name: 'Flux',
            description: 'A tiny state library for screens that mostly read data.',
            kind: 'Library',
            seed: 'Flux',
            // Library blue (BRAND.md s7: one color per kind, everywhere).
            kindColor: brand.blue,
            statusLabel: 'Shipped',
            statusRole: AppStatusRole.success,
          ),
        ),
        SizedBox(height: context.spacing.lg),
        SizedBox(
          height: 340,
          child: ElementCard(
            number: 7,
            symbol: 'Cd',
            name: 'Cadence',
            description: 'A build runner for the slow parts of a release.',
            kind: 'Command-line tool',
            seed: 'Cadence',
            // Command-line tool teal (BRAND.md s7).
            kindColor: brand.teal,
            statusLabel: 'In progress',
            statusRole: AppStatusRole.warning,
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'One color per kind everywhere the kind appears: the symbol, the '
          'kind marker and the rings accent all take it.',
        ),
      ],
    );
  }
}

class _CtaBandStory extends StatelessWidget {
  const _CtaBandStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CtaBand(
          heading: 'Put the brand on your next build',
          message: 'One kit covers color, type, motion and the signature pieces.',
          primaryLabel: 'Start a project',
          secondaryLabel: 'Read the guide',
          onPrimaryPressed: () {},
          onSecondaryPressed: () {},
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Inside the band the tokens retune: text flips to on-orange and '
          'the ring hairline to on-orange at 20%, so the arcs read dark.',
        ),
      ],
    );
  }
}

class _GrayBandStory extends StatelessWidget {
  const _GrayBandStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BandSurface(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _SectionTitle(title: 'By the numbers'),
              SizedBox(height: context.spacing.lg),
              // The grid's stretch rows size themselves to the cards'
              // content.
              const AppStatGrid(
                columns: 2,
                children: <Widget>[
                  AppStatCard(
                    label: 'Builds this month',
                    value: '1,284',
                  ),
                  AppStatCard(
                    label: 'Median build time',
                    value: '3.2 min',
                    hint: 'Across all platforms.',
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The band changes the surface and nothing else: square edges, no '
          'border, page text colors. The orange band is the only colored '
          'section.',
        ),
      ],
    );
  }
}

class _FooterStory extends StatelessWidget {
  const _FooterStory();

  @override
  Widget build(BuildContext context) {
    return const SignatureFooter(name: 'hmziq', copyright: '© 2026 hmziq.');
  }
}

class _BrandIconStory extends StatelessWidget {
  const _BrandIconStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: context.spacing.lg,
          runSpacing: context.spacing.lg,
          children: <Widget>[
            for (final slug in simpleIconPaths.keys)
              SizedBox(
                width: 84,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    BrandIcon(name: slug, size: 28),
                    SizedBox(height: context.spacing.sm),
                    _MonoText(slug),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const BrandIcon(name: 'github', size: 16),
            SizedBox(width: context.spacing.sm),
            Text(
              'starter-cli',
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.foreground,
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.sm),
        const _Caption(
          'The glyph tint follows the icon color like any other icon. Logos '
          'are never recolored to fit a palette; the curated set lives in '
          'marks/simple_icons.dart.',
        ),
      ],
    );
  }
}

class _StepperStory extends StatefulWidget {
  const _StepperStory();

  @override
  State<_StepperStory> createState() => _StepperStoryState();
}

class _StepperStoryState extends State<_StepperStory> {
  int _currentStep = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The numbered ring on its own, for steps laid out by the page.
        const Row(
          spacing: 12,
          children: <Widget>[
            AppStepNumber(index: 0),
            AppStepNumber(index: 1),
            AppStepNumber(index: 2),
          ],
        ),
        const SizedBox(height: 24),
        AppStepper(
          steps: const <AppStepperStep>[
            (
              label: 'Create the workspace',
              description: 'Name it after the project it holds.',
            ),
            (
              label: 'Invite the team',
              description: 'Everyone gets their own sign-in.',
            ),
            (
              label: 'Pick a plan',
              description: null,
            ),
          ],
          currentStep: _currentStep,
          onStepTap: (index) => setState(() => _currentStep = index),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Numbered only because the order is real. Tap a step to move; '
          'feedback is color only.',
        ),
      ],
    );
  }
}

class _SegmentedStory extends StatefulWidget {
  const _SegmentedStory();

  @override
  State<_SegmentedStory> createState() => _SegmentedStoryState();
}

class _SegmentedStoryState extends State<_SegmentedStory> {
  String _value = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppSegmented<String>(
          options: const <AppSegmentOption<String>>[
            (value: 'Monthly', label: 'Monthly', key: null),
            (value: 'Weekly', label: 'Weekly', key: null),
            (value: 'Daily', label: 'Daily', key: null),
          ],
          value: _value,
          onChanged: (value) => setState(() => _value = value),
        ),
        SizedBox(height: context.spacing.lg),
        _Caption('Picked: $_value.'),
      ],
    );
  }
}

class _QuestionsStory extends StatelessWidget {
  const _QuestionsStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppQuestions(
          questions: <AppQuestion>[
            AppQuestion(
              question: 'Where do the tokens come from?',
              answer: 'The theme resolves every color, so both modes read right.',
              initiallyOpen: true,
            ),
            AppQuestion(
              question: 'Can I use a material on body text?',
              answer: 'Materials belong on display-size headings only.',
            ),
            AppQuestion(
              question: 'When does a ring fill?',
              answer: 'When the thing it stands for is on, open, done or selected.',
            ),
          ],
        ),
        SizedBox(height: context.spacing.xl),
        // Numbered FAQs (question.svelte's number): orange digits, no ring.
        const AppQuestions(
          questions: <AppQuestion>[
            AppQuestion(question: 'What does it cost?', answer: 'Nothing.', number: 1),
            AppQuestion(question: 'Where does it run?', answer: 'Anywhere.', number: 2),
          ],
        ),
        SizedBox(height: context.spacing.xl),
        // A topic names itself in a grey tag at the row's end.
        const AppQuestions(
          questions: <AppQuestion>[
            AppQuestion(question: 'How do I add a provider?', answer: 'Restart.', topic: 'Setup'),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The answer appears without animation, like the details element '
          'this block mirrors. Numbered questions trade the ring for orange '
          'digits; a topic rides at the row end in a grey tag.',
        ),
      ],
    );
  }
}

class _CodeStory extends StatelessWidget {
  const _CodeStory();

  @override
  Widget build(BuildContext context) {
    const source = r'''
void main() {
  for (var i = 0; i < 3; i++) {
    print('hello $i'); // machine values run in mono
  }
}''';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppCodeBlock(
          source: source,
          label: 'main.dart',
          copyLabel: 'Copy the sample',
        ),
        SizedBox(height: context.spacing.lg),
        // A bare command with no bar carries its copy button floating at
        // the block's top right corner (code-block.svelte's copy && !bar).
        const AppCodeBlock(source: 'flutter pub add forui', copyLabel: 'Copy the command'),
        SizedBox(height: context.spacing.lg),
        const AppCodeBlock(
          copyLabel: 'Copy the shown file',
          files: <AppCodeFile>[
            AppCodeFile(label: 'Terminal', source: 'flutter pub add forui'),
            AppCodeFile(label: 'pubspec.yaml', source: 'dependencies:\n  forui: ^0.25.0'),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const AppCommandBar(
          command: 'flutter pub add forui --dev',
          copyLabel: 'Copy the command',
        ),
        SizedBox(height: context.spacing.lg),
        // The editor variant (code-lines.svelte): a gutter number per row
        // and the row under the pointer tinted primary at 8%.
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                color: context.theme.colors.border,
                width: context.theme.style.borderWidth,
              ),
              borderRadius: context.theme.style.borderRadius.lg,
            ),
          ),
          child: const AppCodeLines(source: source, lineNumbers: true),
        ),
        SizedBox(height: context.spacing.lg),
        // Inline code: machine values in a sentence sit in a mono chip.
        Text.rich(
          TextSpan(
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            children: const <InlineSpan>[
              TextSpan(text: 'Run '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AppInlineCode('flutter run'),
              ),
              TextSpan(text: ' and the app opens with every page working.'),
            ],
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Code people only read ships without a button; the copy button '
          'appears only when copying is the point — in the bar, or floating '
          'when there is no bar. Tabs switch versions of the same file; '
          'editor lines number their rows and tint the one under the pointer.',
        ),
      ],
    );
  }
}

class _TerminalStory extends StatelessWidget {
  const _TerminalStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The replay button rides the title bar's end (terminal.stories'
        // "With actions").
        AppTerminalWindow(
          title: 'release.log',
          actions: <Widget>[
            FButton.icon(
              variant: FButtonVariant.ghost,
              size: FButtonSizeVariant.sm,
              onPress: () {},
              child: const Icon(FLucideIcons.rotateCcw),
            ),
          ],
          lines: const <AppTerminalLine>[
            AppTerminalLine.command('just build macos'),
            AppTerminalLine.note('production config'),
            AppTerminalLine.step('compiled 128 files', answer: '4 targets'),
            AppTerminalLine.result('built in 74.3s'),
            AppTerminalLine.keyValue('Binary', 'build/macos/Release.app'),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        // Bare lines, no window: the run a page drops between paragraphs
        // (terminal.stories' "Lines"), in the ambient theme.
        const AppTerminalLines(
          lines: <AppTerminalLine>[
            AppTerminalLine.command('just build macos'),
            AppTerminalLine.note('production config'),
            AppTerminalLine.step('compiled 128 files', answer: '4 targets'),
            AppTerminalLine.result('built in 74.3s'),
            AppTerminalLine.keyValue('Binary', 'build/macos/Release.app'),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The window re-themes itself dark, so the lines stay readable on '
          'a light page. The prompt and the step marker draw in oxide; a '
          'step answers in green behind a muted ›. Bare lines keep the '
          'ambient theme — only the window is the dark island.',
        ),
      ],
    );
  }
}

class _TableStory extends StatelessWidget {
  const _TableStory();

  @override
  Widget build(BuildContext context) {
    const columns = <String>['Plan', 'Events', 'History'];
    const rows = <List<String>>[
      <String>['Solo', '10,000', '30 days'],
      <String>['Team', '100,000', '90 days'],
      <String>['Studio', '1,000,000', '1 year'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionTitle(title: 'Boxed, with the accent column'),
        SizedBox(height: context.spacing.sm),
        // The table hugs its columns like the svelte auto-layout, so the
        // stories center it instead of stretching it across the page.
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppDataTable(columns: columns, rows: rows, accentColumn: 1),
        ),
        SizedBox(height: context.spacing.lg),
        const _SectionTitle(title: 'Docs lines'),
        SizedBox(height: context.spacing.sm),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppDataTable(columns: columns, rows: rows, style: AppDataTableStyle.docs),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Names in the first column stay in the text color; the other '
          'cells read muted so the accent column stands out.',
        ),
      ],
    );
  }
}

class _SummaryStory extends StatelessWidget {
  const _SummaryStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppSummaryBox(
          label: 'TL;DR',
          body:
              'Every color comes from a token, status is always soft, and '
              'only orange is ever a solid fill behind text.',
        ),
        SizedBox(height: context.spacing.lg),
        const AppSummaryBox(
          label: 'The short version',
          body:
              'Legal pages use the same box: one paragraph that says what '
              'the section means.',
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The label and its ring carry the primary; the body stays in the '
          'regular text colors.',
        ),
      ],
    );
  }
}

class _ListsStory extends StatelessWidget {
  const _ListsStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppBullets(
          items: <String>[
            'Lead with the outcome.',
            'One idea per sentence.',
            'Buttons say what happens.',
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const AppCheckList(
          items: <AppCheckItem>[
            (label: 'At least 12 characters', checked: true),
            (label: 'One number', checked: true),
            (label: 'One symbol', checked: false),
            (label: 'Not your email', checked: false),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Bullets stay hollow; a checklist row fills green only when its '
          'rule is met, and the words always carry the meaning.',
        ),
      ],
    );
  }
}

class _NumbersStory extends StatelessWidget {
  const _NumbersStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppBigNumbers(
          numbers: <AppBigNumber>[
            (value: '128', label: 'Projects seeded'),
            (value: '16', label: 'Approved materials'),
            (value: '5', label: 'Status roles'),
          ],
        ),
        SizedBox(height: context.spacing.xl),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppMetricTrend(change: 0.12, comparison: 'vs last 30 days'),
            SizedBox(height: 8),
            AppMetricTrend(change: -0.028, good: AppTrendGood.down, comparison: 'bounce rate'),
            SizedBox(height: 8),
            AppMetricTrend(change: 0, noChangeLabel: 'No change', comparison: 'uptime'),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The arrow follows the direction, the color follows the meaning, '
          'and the words always carry a sign.',
        ),
      ],
    );
  }
}

class _StatsStory extends StatelessWidget {
  const _StatsStory();

  @override
  Widget build(BuildContext context) {
    return const AppStatGrid(
      columns: 3,
      children: <Widget>[
        AppStatCard(
          label: 'Visitors',
          value: '48,210',
          trend: AppMetricTrend(change: 0.12),
        ),
        AppStatCard(
          label: 'Bounce rate',
          value: '42.1%',
          trend: AppMetricTrend(change: -0.03, good: AppTrendGood.down),
        ),
        AppStatCard(
          label: 'p95 latency',
          value: '1.8 s',
          hint: 'Rolling 24 hours.',
        ),
      ],
    );
  }
}

class _UsageStory extends StatelessWidget {
  const _UsageStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppUsageMeter(
          label: 'Events this month',
          used: 7420,
          limit: 10000,
          unit: 'events',
          valueText: '7,420 of 10,000 events',
          resetsOn: 'Resets on 1 November',
        ),
        SizedBox(height: context.spacing.xl),
        const AppUsageMeter(
          label: 'Seats',
          used: 9,
          limit: 10,
          unit: 'seats',
          valueText: '9 of 10 seats',
        ),
        SizedBox(height: context.spacing.xl),
        AppUsageMeter(
          label: 'Build minutes',
          used: 2000,
          limit: 2000,
          unit: 'minutes',
          valueText: '2,000 of 2,000 minutes',
          limitMessage: "You've used every build minute this month.",
          action: TextButton(
            onPressed: () {},
            child: const Text('Add minutes'),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Primary below the warning level, warning from it, destructive at '
          'the limit. The bar never carries text.',
        ),
      ],
    );
  }
}

class _BeforeAfterStory extends StatelessWidget {
  const _BeforeAfterStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppBeforeAfter(
          beforeLabel: 'By hand',
          afterLabel: 'With the kit',
          rows: <AppBeforeAfterRow>[
            AppBeforeAfterRow(
              what: 'Colors',
              before: 'Pick hexes per screen.',
              after: 'Resolve tokens from the theme.',
            ),
            AppBeforeAfterRow(
              what: 'Status',
              before: 'Restyle status chips everywhere.',
              after: 'Status roles stay soft everywhere.',
            ),
            AppBeforeAfterRow(
              what: 'Modes',
              before: 'Hope the modes match.',
              after: 'Both modes read right by construction.',
            ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'One hairline list: the before items strike through in muted words '
          'and the after items carry the filled primary ring; the wide row '
          'grows the 16rem "what" column and the arrow.',
        ),
      ],
    );
  }
}

class _PageIntroStory extends StatelessWidget {
  const _PageIntroStory();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppPageIntro(
          title: 'Billing',
          description: 'See what each plan includes and change it any time.',
        ),
      ],
    );
  }
}

class _CommandsStory extends StatelessWidget {
  const _CommandsStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionTitle(title: 'Bare command'),
        SizedBox(height: context.spacing.sm),
        const AppCommandLine(command: 'flutter pub add forui'),
        SizedBox(height: context.spacing.sm),
        const AppCommandLine(command: 'flutter build macos --release --obfuscate'),
        SizedBox(height: context.spacing.sm),
        const _Caption(
          'The bare line for prose and lists: the prompt in the primary, '
          'the program in blue, flags in the primary and quoted values in '
          'green. The sigil is not part of the copy.',
        ),
        SizedBox(height: context.spacing.xl),
        const _SectionTitle(title: 'Command box'),
        SizedBox(height: context.spacing.sm),
        const AppCommandBox(
          command: 'just gen',
          copyLabel: 'Copy the command',
          copiedLabel: 'Copied',
        ),
        SizedBox(height: context.spacing.sm),
        const _Caption(
          "The bar's smaller pill: one mono command with an icon copy "
          'button, the kind a step in a list carries.',
        ),
        SizedBox(height: context.spacing.xl),
        const _SectionTitle(title: 'Command palette'),
        SizedBox(height: context.spacing.sm),
        AppCommandPalette(
          commands: <AppCommand>[
            AppCommand(
              label: 'Open the gallery home',
              section: 'Navigate',
              icon: FLucideIcons.house,
              shortcutLabel: 'G H',
              onSelected: () {},
            ),
            AppCommand(
              label: 'Toggle the accent',
              section: 'Settings',
              icon: FLucideIcons.palette,
              shortcutLabel: 'A',
              onSelected: () {},
            ),
            AppCommand(
              label: 'Copy diagnostics',
              section: 'Settings',
              icon: FLucideIcons.copy,
              onSelected: () {},
            ),
          ],
        ),
        SizedBox(height: context.spacing.sm),
        const _Caption(
          'Type to filter by label or section; results group under their '
          'section headings and the footer names the first result. The '
          'host owns the sheet this panel sits in.',
        ),
      ],
    );
  }
}

class _DetailSectionStory extends StatelessWidget {
  const _DetailSectionStory();

  @override
  Widget build(BuildContext context) {
    return const AppDetailSection(
      title: 'Workspace',
      description: 'Facts about the workspace this build belongs to.',
      items: <AppDetailItem>[
        AppDetailItem(label: 'Name', value: 'starter'),
        AppDetailItem(label: 'Region', value: 'eu-central'),
        AppDetailItem(label: 'API key', value: 'sk_live_9f2c', mono: true, copyable: true),
        AppDetailItem(label: 'Legacy id'),
      ],
      copyLabel: 'Copy the key',
      footer: Text('Opened 12 October 2026'),
    );
  }
}

class _PeopleStory extends StatelessWidget {
  const _PeopleStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppPersonCard(
          name: 'Hmziq Rs',
          role: 'Maintainer',
          bio: 'Keeps the starter honest: tokens in, brand out.',
          links: <String>['github.com/hmziqrs'],
          trailing: AppStatusTag(label: 'Owner', role: AppStatusRole.info),
        ),
        SizedBox(height: context.spacing.lg),
        const AppPersonCard(name: 'Ada Byron'),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The avatar draws its initials in a hollow ring above the name; '
          'a person without a role shows as just the name.',
        ),
      ],
    );
  }
}

class _ReleasesStory extends StatelessWidget {
  const _ReleasesStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppReleaseCard(
          version: '0.12.0',
          date: 'August 26, 2026',
          product: 'claude-multi',
          symbol: 'Cm',
          symbolLabel: 'claude-multi mark',
          latestLabel: 'Latest',
          groups: <AppReleaseGroup>[
            (
              kind: AppReleaseChangeKind.changed,
              lines: <String>[
                'GLM template update: sonnet-tier now maps to glm-5.3-flash.',
              ],
            ),
          ],
          installs: <AppReleaseInstall>[
            (manager: 'bun', command: 'bun add -g claude-multi'),
            (manager: 'npm', command: 'npm install -g claude-multi'),
            (manager: 'deno', command: 'deno install -g claude-multi'),
          ],
          notesLabel: 'All release notes',
        ),
        SizedBox(height: context.spacing.lg),
        const AppReleaseCard(
          version: '0.11.1',
          date: 'August 22, 2026',
          product: 'claude-multi',
          symbol: 'Cm',
          symbolLabel: 'claude-multi mark',
          groups: <AppReleaseGroup>[
            (
              kind: AppReleaseChangeKind.fixed,
              lines: <String>[
                'Existing instances can now pick up provider template changes.',
                'Provider detection now accepts endpoints with a trailing slash.',
                'Doctor spots environment values that differ from the current template.',
              ],
            ),
            (
              kind: AppReleaseChangeKind.changed,
              lines: <String>[
                'Migrations and the instance-details sync use the same environment code.',
              ],
            ),
          ],
          notesLabel: 'All release notes',
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The version runs large in mono; each kind of change keeps its one '
          'color, and the update command follows the package manager.',
        ),
      ],
    );
  }
}

class _EndpointsStory extends StatelessWidget {
  const _EndpointsStory();

  @override
  Widget build(BuildContext context) {
    // Example month: green means delivered on the first try, the two amber
    // days needed retries, the red day failed.
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppEndpointCard(
          url: 'https://api.paperplane.app/hooks/hookline',
          startLabel: 'Sep 14',
          days: <double>[
            1, 1, 1, 1, 0.97, 1, 1, 1, 1, 1, 1, 0.5, 1, 1, 1, 1, 1, 1, 1, 1, //
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
          ],
          metrics: <AppEndpointMetric>[
            (label: 'First try', value: '99.4%'),
            (label: 'Median time', value: '182 ms'),
            (label: 'Retried', value: '41'),
          ],
          deliveries: <AppEndpointDelivery>[
            (event: 'invoice.paid', status: 200, at: '12:04:31'),
            (event: 'customer.updated', status: 200, at: '12:03:58'),
            (event: 'order.created', status: 503, at: '12:01:12'),
          ],
          primaryLabel: 'Send a test event',
          secondaryLabel: 'Pause',
        ),
      ],
    );
  }
}

class _TocStory extends StatefulWidget {
  const _TocStory();

  @override
  State<_TocStory> createState() => _TocStoryState();
}

class _TocStoryState extends State<_TocStory> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppToc(
          entries: <AppTocEntry>[
            for (final (index, label) in _labels.indexed)
              AppTocEntry(label: label, active: index == _active),
          ],
          onSelected: (index) => setState(() => _active = index),
          semanticLabel: 'On this page',
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption('Tap a section; the ring and the text color carry the change.'),
      ],
    );
  }

  static const _labels = <String>['Overview', 'Install', 'Configure', 'Ship'];
}

class _LineTabsStory extends StatefulWidget {
  const _LineTabsStory();

  @override
  State<_LineTabsStory> createState() => _LineTabsStoryState();
}

class _LineTabsStoryState extends State<_LineTabsStory> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppLineTabs(
          tabs: const <String>['Overview', 'Members', 'Billing'],
          counts: const <int?>[12, 3, null],
          selectedIndex: _selected,
          onSelected: (index) => setState(() => _selected = index),
          semanticLabel: 'Sections',
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Tap a tab; the underline and text color carry the change and the '
          'count chip never moves.',
        ),
      ],
    );
  }
}

class _EyebrowStory extends StatelessWidget {
  const _EyebrowStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppEyebrow('Where the work goes', index: 2),
        SizedBox(height: context.spacing.lg),
        const AppEyebrow('Where the work goes', variant: AppEyebrowVariant.rule),
        SizedBox(height: context.spacing.lg),
        const AppEyebrow(
          'Where the work goes',
          variant: AppEyebrowVariant.count,
          index: 3,
          total: 5,
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'The ring, the rule and the ticks all draw in the primary; the '
          'rule variant leaves the words muted.',
        ),
      ],
    );
  }
}
