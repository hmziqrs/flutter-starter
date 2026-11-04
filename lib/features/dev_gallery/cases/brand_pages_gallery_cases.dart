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
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/blocks/big_numbers.dart';
import 'package:starter/shared/widgets/blocks/check_list.dart';
import 'package:starter/shared/widgets/blocks/code_block.dart';
import 'package:starter/shared/widgets/blocks/data_table.dart';
import 'package:starter/shared/widgets/blocks/link_bar.dart';
import 'package:starter/shared/widgets/blocks/person_card.dart';
import 'package:starter/shared/widgets/blocks/question.dart';
import 'package:starter/shared/widgets/blocks/ring_stats.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';
import 'package:starter/shared/widgets/blocks/stepper.dart';
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/brand/app_notice.dart';
import 'package:starter/shared/widgets/brand/app_ring_gauge.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';
import 'package:starter/shared/widgets/glass/glass_panel.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';
import 'package:starter/shared/widgets/lists/equal_height_row.dart';
import 'package:starter/shared/widgets/marks/app_mark.dart';
import 'package:starter/shared/widgets/marks/band_surface.dart';
import 'package:starter/shared/widgets/marks/brand_icon.dart';
import 'package:starter/shared/widgets/marks/cta_band.dart';
import 'package:starter/shared/widgets/marks/material_card.dart';
import 'package:starter/shared/widgets/marks/material_sparkline.dart';
import 'package:starter/shared/widgets/marks/signature_footer.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
import 'package:starter/shared/widgets/rings/corner_rings.dart';

/// Which whole page the gallery composes.
///
/// Each case is one end-to-end scrollable page built from the brand kit the
/// way the site templates compose them (`sightline.svelte`,
/// `showcase-section`, `band-section`, `pricing-plans`), measured against the
/// captured page references in `build/brand-refs/pages/`.
enum BrandPageKind {
  /// The SaaS landing: wave hero, app window, logo row, bento, steps, ring
  /// stats, privacy band, quotes, plans, questions, closing band, signature.
  saasLanding,

  /// The product tour: split hero over a material, feature bento, showcase
  /// over the rings, numbers band, big quote, closing band, signature.
  product,

  /// The pricing page: page intro, billing switch, plans, comparison table,
  /// numbered questions, closing band, signature.
  pricing,

  /// The company page: page intro, big numbers, values, quote band, team,
  /// testimonial wall, works-alongside row, closing band, signature.
  company,
}

/// Builds the "Pages" gallery cases: whole end-to-end pages composed from the
/// brand kit's blocks, marks, materials, glass and rings.
List<GalleryCase> buildBrandPagesGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandPageKind.values)
      TypedGalleryCase<BrandPageKind>(
        id: 'pages.${kind.name}',
        screenId: 'brandPages',
        screenLabelBuilder: (_) => 'Pages',
        caseLabelBuilder: (_) => _pageCaseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _BrandPage(kind: state),
      ),
  ];
}

String _pageCaseLabel(BrandPageKind kind) => switch (kind) {
  BrandPageKind.saasLanding => 'SaaS landing page',
  BrandPageKind.product => 'Product tour page',
  BrandPageKind.pricing => 'Pricing page',
  BrandPageKind.company => 'Company page',
};

/// The page case itself: the ambient gallery theme re-pinned to the brand
/// accent (the pages demonstrate the orange signature, BRAND.md s4), then the
/// page's own scroll view.
class _BrandPage extends ConsumerWidget {
  const _BrandPage({required this.kind});

  final BrandPageKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
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
        child: ColoredBox(
          color: brandTheme.colors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (kind == BrandPageKind.saasLanding) ..._landingChrome(),
              _SiteHeader(
                siteName: switch (kind) {
                  BrandPageKind.saasLanding => 'sightline',
                  BrandPageKind.product => 'oxiwake',
                  BrandPageKind.pricing => 'sightline',
                  BrandPageKind.company => 'hmziq',
                },
                nav: switch (kind) {
                  BrandPageKind.saasLanding || BrandPageKind.pricing => const <String>[
                    'Product',
                    'Pricing',
                    'Customers',
                    'Docs',
                  ],
                  BrandPageKind.product => const <String>[
                    'Product',
                    'Docs',
                    'Pricing',
                    'Changelog',
                  ],
                  BrandPageKind.company => const <String>['About', 'Blog', 'Careers', 'Contact'],
                },
                current: switch (kind) {
                  BrandPageKind.pricing => 'Pricing',
                  BrandPageKind.company => 'About',
                  _ => null,
                },
              ),
              switch (kind) {
                BrandPageKind.saasLanding => const _SaasLandingPageBody(),
                BrandPageKind.product => const _ProductPageBody(),
                BrandPageKind.pricing => const _PricingPageBody(),
                BrandPageKind.company => const _CompanyPageBody(),
              },
              _SiteFooter(
                siteName: switch (kind) {
                  BrandPageKind.saasLanding || BrandPageKind.pricing => 'sightline',
                  BrandPageKind.product => 'oxiwake',
                  BrandPageKind.company => 'hmziq',
                },
                symbol: switch (kind) {
                  BrandPageKind.saasLanding || BrandPageKind.pricing => 'Sl',
                  BrandPageKind.product => 'Ox',
                  BrandPageKind.company => 'Hq',
                },
                tagline: switch (kind) {
                  BrandPageKind.saasLanding ||
                  BrandPageKind.pricing => 'Product analytics that answers in plain words.',
                  BrandPageKind.product => 'A synthesizer that lives in a folder of files.',
                  BrandPageKind.company => 'Tools that run on your machine and stay there.',
                },
                columns: switch (kind) {
                  BrandPageKind.saasLanding || BrandPageKind.pricing => const <_FooterColumn>[
                    _FooterColumn('Product', <String>[
                      'Overview',
                      'Funnels',
                      'Retention',
                      'Live view',
                      'Pricing',
                    ]),
                    _FooterColumn('Resources', <String>['Docs', 'Guides', 'Changelog', 'Status']),
                    _FooterColumn('Company', <String>['About', 'Customers', 'Careers', 'Contact']),
                    _FooterColumn('Compare', <String>['Google Analytics', 'Mixpanel', 'Amplitude']),
                  ],
                  BrandPageKind.product => const <_FooterColumn>[
                    _FooterColumn('Product', <String>[
                      'Studio',
                      'Patches',
                      'Instruments',
                      'Pricing',
                    ]),
                    _FooterColumn('Resources', <String>[
                      'Manual',
                      'Sound library',
                      'Changelog',
                      'Status',
                    ]),
                    _FooterColumn('Company', <String>['About', 'Blog', 'Careers', 'Contact']),
                    _FooterColumn('Compare', <String>['Ableton', 'Bitwig', 'Reason']),
                  ],
                  BrandPageKind.company => const <_FooterColumn>[
                    _FooterColumn('Projects', <String>[
                      'Freeoxide',
                      'Sightline',
                      'Oxiwake',
                      'Parley',
                    ]),
                    _FooterColumn('Writing', <String>['Blog', 'Notes', 'Talks']),
                    _FooterColumn('Company', <String>['About', 'Contact']),
                    _FooterColumn('Elsewhere', <String>['GitHub', 'Mastodon', 'RSS']),
                  ],
                },
                copyright: switch (kind) {
                  BrandPageKind.saasLanding ||
                  BrandPageKind.pricing => '© 2026 Sightline. Example content for a SaaS template.',
                  BrandPageKind.product => '© 2026 Oxiwake. Example content for a SaaS template.',
                  BrandPageKind.company => '© 2026 hmziq. Free and open source where it says so.',
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _landingChrome() => const <Widget>[_AnnouncementBar()];

/// ---------------------------------------------------------------------------
/// Page bodies
/// ---------------------------------------------------------------------------

/// The landing page: hero, app window, logo row, then the sections at the
/// landing rhythm (`gap-24`, 96px, from `site-shell.svelte`).
class _SaasLandingPageBody extends StatelessWidget {
  const _SaasLandingPageBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _WaveHero(
          badgeLead: 'New',
          badgeRest: ' · rings for every site',
          title: 'See which features\npeople use, and\nwhere they give up.',
          lede:
              'Sightline turns clicks into plain answers. It shows what brings people in, where they '
              'get stuck and what makes them come back. Add one line to your site and the charts '
              'fill in by themselves.',
          primaryLabel: 'Start free',
          secondaryLabel: 'Book a demo',
          notes: <String>['Free up to 10,000 visitors a month', 'No cookie banner needed'],
        ),
        const _SectionGap(),
        const _Container(
          child: _AppWindow(),
        ),
        const _SectionGap(),
        const _Container(
          child: _LogoCloud(
            label: 'Product teams that open Sightline every morning',
            customers: <_Customer>[
              _Customer('Paperplane', FLucideIcons.bird),
              _Customer('Northwind', FLucideIcons.mountain),
              _Customer('Tidewater', FLucideIcons.waves),
              _Customer('Fernhill', FLucideIcons.leaf),
              _Customer('Lumabank', FLucideIcons.landmark),
              _Customer('Hexwork', FLucideIcons.hexagon),
              _Customer('Cumulus', FLucideIcons.cloudy),
            ],
          ),
        ),
        const _SectionGap(),
        const _Container(
          child: _SectionHead(
            title: 'Every question a product team asks, answered',
            intro: 'The five reports people actually use, built for you from the moments you name.',
            center: true,
            child: _LandingBento(),
          ),
        ),
        const _SectionGap(),
        const _Container(
          child: _SectionHead(
            title: 'Set up in five minutes',
            intro: 'If you can paste a line into your site, you can set up Sightline.',
            child: _StepsAndCode(),
          ),
        ),
        const _SectionGap(),
        const _Container(
          child: AppRingStats(
            stats: <AppRingStat>[
              (value: '4 kB', label: 'script, loaded after your page', share: 0.04, count: null),
              (value: '2 s', label: 'from a click to your charts', share: 0.2, count: null),
              (value: '0', label: 'cookies set on your visitors', share: 0, count: null),
            ],
          ),
        ),
        const _SectionGap(),
        const _PrivacyBand(),
        const _SectionGap(),
        const _Container(
          child: _SectionHead(
            title: 'What product teams say',
            intro: 'Three of the teams that moved to Sightline this year.',
            child: _QuoteRow(
              quotes: _landingQuotes,
            ),
          ),
        ),
        const _SectionGap(),
        const _Container(child: _PricingPlansSection(headline: 'Pricing that grows with you')),
        const _SectionGap(),
        _Container(
          child: _SectionHead(
            title: 'Questions people ask',
            intro: 'Straight answers about privacy, speed and billing.',
            child: AppQuestions(
              questions: <AppQuestion>[
                for (final (index, item) in _faqItems.indexed)
                  AppQuestion(
                    question: item.question,
                    answer: item.answer,
                    initiallyOpen: index == 0,
                  ),
              ],
            ),
          ),
        ),
        const _SectionGap(),
        const CtaBand(
          heading: 'Know what your users do by Friday.',
          message:
              "Add the script today. By the end of the week you'll have a funnel, a retention chart "
              'and a clear next step.',
          primaryLabel: 'Start free',
          secondaryLabel: 'Book a demo',
        ),
      ],
    );
  }
}

/// The product tour: split hero over a material, feature bento, the showcase
/// over the rings, numbers, one big quote, closing band.
class _ProductPageBody extends StatelessWidget {
  const _ProductPageBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _SplitHero(),
        _SectionGap(),
        _Container(
          child: _SectionHead(
            title: 'Everything a release needs, in one window',
            intro:
                'Patches, instruments and the mix — arranged on one canvas, wired the way you think.',
            center: true,
            child: _FeatureBento(),
          ),
        ),
        _SectionGap(),
        _ShowcaseOverRings(),
        _SectionGap(),
        _NumbersBand(),
        _SectionGap(),
        _Container(
          child: _BigQuote(
            quote:
                'We replaced four plugins and a spreadsheet of license keys. The studio is a folder '
                'of files, so moving machines took an afternoon, not a week.',
            name: 'Ana Duarte',
            role: 'Producer, Fernhill',
          ),
        ),
        _SectionGap(),
        CtaBand(
          heading: 'Hear your record by Sunday.',
          message:
              'Open the demo, drag a folder of sounds in, and play. When it clicks, the license is '
              'one file you own.',
          primaryLabel: 'Download the demo',
          secondaryLabel: 'Read the manual',
        ),
      ],
    );
  }
}

/// The pricing page: intro, billing switch and plans, comparison table,
/// numbered questions, closing band.
class _PricingPageBody extends StatelessWidget {
  const _PricingPageBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 64),
        const _Container(
          child: _CenteredIntro(
            kicker: 'Pricing',
            title: 'Pay for the visitors,\nnot the seats.',
            lede:
                'Every plan includes unlimited people. Start free, and the price follows your '
                'traffic — not your team.',
          ),
        ),
        const SizedBox(height: 48),
        const _Container(child: _PricingPlansSection(headline: null, compactIntro: true)),
        const _SectionGap(),
        const _Container(
          child: _SectionHead(
            title: 'Compare plans',
            intro: 'The whole grid, so nobody has to guess what "everything" means.',
            child: _ComparisonTable(),
          ),
        ),
        const _SectionGap(),
        _Container(
          child: _SectionHead(
            title: 'Questions people ask',
            intro: 'Straight answers about billing, limits and privacy.',
            child: AppQuestions(
              questions: <AppQuestion>[
                for (final (index, item) in _faqItems.indexed)
                  AppQuestion(
                    question: item.question,
                    answer: item.answer,
                    number: index + 1,
                    topic: item.topic,
                    initiallyOpen: index == 0,
                  ),
              ],
            ),
          ),
        ),
        const _SectionGap(),
        const CtaBand(
          heading: 'Start free. Upgrade when it sticks.',
          message:
              'The free plan runs real projects. When a chart starts mattering on Monday morning, '
              'Growth is one click away.',
          primaryLabel: 'Start free',
          secondaryLabel: 'Talk to us',
        ),
      ],
    );
  }
}

/// The company page: intro, big numbers, values, quote band, team,
/// testimonial wall, works-alongside row, closing band.
class _CompanyPageBody extends StatelessWidget {
  const _CompanyPageBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(height: 64),
        _Container(
          child: _CenteredIntro(
            kicker: 'About',
            title: 'We build tools that\nstay yours.',
            lede:
                'hmziq is a small team making software that runs on your machine, keeps your files, '
                'and answers to nobody but you.',
          ),
        ),
        _SectionGap(),
        _Container(
          child: AppBigNumbers(
            numbers: <AppBigNumber>[
              (value: '2019', label: 'the year of the first commit'),
              (value: '9', label: 'people, four time zones'),
              (value: '38k', label: 'projects created every month'),
              (value: '0', label: 'trackers in anything we ship'),
            ],
            columns: 4,
            fontSize: 40,
          ),
        ),
        _SectionGap(),
        _Container(
          child: _SectionHead(
            title: 'What we believe',
            intro: 'Three rules every project in the family is held to.',
            child: _ValuesRow(),
          ),
        ),
        _SectionGap(),
        _GrayQuoteBand(),
        _SectionGap(),
        _Container(
          child: _SectionHead(
            title: 'The people behind it',
            intro: 'Everyone who builds the family, in the order they joined.',
            child: _TeamGrid(),
          ),
        ),
        _SectionGap(),
        _Container(
          child: _SectionHead(
            title: 'People keep their words here',
            intro: 'Notes from the people who moved their work to these tools.',
            child: _TestimonialWall(),
          ),
        ),
        _SectionGap(),
        _Container(child: _WorksAlongside()),
        _SectionGap(),
        CtaBand(
          heading: 'Come build the next one with us.',
          message:
              'The family is open source where it says so, and the roadmap is public. Say hello '
              'before the next project starts.',
          primaryLabel: 'Read the roadmap',
          secondaryLabel: 'Say hello',
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Shared frame pieces (announcement, header, footer, containers, buttons)
/// ---------------------------------------------------------------------------

/// The site column (`container.svelte`): default max-w-5xl (1024), wide
/// max-w-[82rem] (1312), always 24px of side padding, centered.
class _Container extends StatelessWidget {
  const _Container({required this.child, this.wide = false});

  final Widget child;

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 1312 : 1024),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

/// The landing rhythm's gap between sections (`site-shell.svelte` main:
/// `gap-24 md:gap-32` — 96 at reading widths, 64 below).
class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 768;
    return SizedBox(height: wide ? 96 : 64);
  }
}

/// The one-line strip above the header (`saas-shell.svelte` banner): the
/// orange tag, the sentence, and the w500 link with its arrow.
class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: <Widget>[
          const _OrangeTag(label: 'New'),
          Text(
            'Funnels now show where people leave, step by step.',
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "See what's new",
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(FLucideIcons.arrowRight, size: 14, color: theme.colors.foreground),
            ],
          ),
        ],
      ),
    );
  }
}

/// The site header (`site-shell.svelte`): wordmark at the start, ghost nav
/// links and the sign-in ghost, the sm filled CTA at the end, all inside the
/// default column at h-19 (76px). Nav hides below md like the site does.
class _SiteHeader extends StatelessWidget {
  const _SiteHeader({required this.siteName, required this.nav, this.current});

  final String siteName;

  final List<String> nav;

  final String? current;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: SizedBox(
            height: 76,
            child: Row(
              children: <Widget>[
                AppWordmark(name: siteName),
                const Spacer(),
                // The nav reads only from md up; narrow panes keep the
                // wordmark and the CTA, like the site's `hidden md:flex`.
                if (MediaQuery.sizeOf(context).width >= 768) ...<Widget>[
                  for (final item in nav) ...<Widget>[
                    _SiteButton(
                      label: item,
                      variant: _SiteButtonVariant.ghost,
                      size: _SiteButtonSize.sm,
                      active: item == current,
                    ),
                    const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 16),
                  const _SiteButton(
                    label: 'Sign in',
                    variant: _SiteButtonVariant.ghost,
                    size: _SiteButtonSize.sm,
                  ),
                  const SizedBox(width: 12),
                ],
                const _SiteButton(
                  label: 'Start free',
                  size: _SiteButtonSize.sm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SiteButtonVariant { filled, outline, ghost }

enum _SiteButtonSize { sm, lg }

/// A site button (`button-link.svelte` over shadcn): h-10 lg / h-8 sm,
/// rounded-md, 14px w500 labels; the filled variant paints the primary with
/// the on-primary text, the outline the border, the ghost muted words.
class _SiteButton extends StatelessWidget {
  const _SiteButton({
    required this.label,
    this.variant = _SiteButtonVariant.filled,
    this.size = _SiteButtonSize.lg,
    this.active = false,
  });

  final String label;

  final _SiteButtonVariant variant;

  final _SiteButtonSize size;

  /// For ghost nav items: the page you're on reads in the foreground.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final small = size == _SiteButtonSize.sm;
    final shape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    final textStyle = WidgetStatePropertyAll(
      TextStyle(
        fontSize: 14,
        height: 1,
        fontWeight: FontWeight.w500,
        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
      ),
    );
    final content = switch (variant) {
      _SiteButtonVariant.filled => theme.colors.primaryForeground,
      _SiteButtonVariant.outline => theme.colors.foreground,
      _SiteButtonVariant.ghost => active ? theme.colors.foreground : theme.colors.mutedForeground,
    };
    final backgroundColor = WidgetStateProperty.resolveWith<Color?>((states) {
      final hovered = states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed);
      return switch (variant) {
        _SiteButtonVariant.filled =>
          hovered ? theme.colors.primary.withValues(alpha: 0.88) : theme.colors.primary,
        _SiteButtonVariant.outline => hovered ? theme.colors.muted : Colors.transparent,
        _SiteButtonVariant.ghost =>
          hovered ? theme.colors.foreground.withValues(alpha: 0.08) : Colors.transparent,
      };
    });
    final style = ButtonStyle(
      backgroundColor: backgroundColor,
      foregroundColor: WidgetStatePropertyAll(content),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: WidgetStatePropertyAll(Size(48, small ? 34 : 40)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: small ? 14 : 20),
      ),
      shape: shape,
      side: WidgetStatePropertyAll(
        switch (variant) {
          _SiteButtonVariant.outline => BorderSide(color: theme.colors.border),
          _ => BorderSide.none,
        },
      ),
      textStyle: textStyle,
    );
    return switch (variant) {
      _SiteButtonVariant.outline => OutlinedButton(
        onPressed: () {},
        style: style,
        child: Text(label),
      ),
      _SiteButtonVariant.ghost => TextButton(
        onPressed: () {},
        style: style,
        child: Text(label),
      ),
      _SiteButtonVariant.filled => ElevatedButton(
        onPressed: () {},
        style: style,
        child: Text(label),
      ),
    };
  }
}

/// The orange soft tag (`tag.svelte` tone=orange): the primary at its soft
/// fill, primary words, the small ring marker before them.
class _OrangeTag extends StatelessWidget {
  const _OrangeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final primary = theme.colors.primary;
    final fillOpacity = theme.colors.brightness == Brightness.dark ? 0.2 : 0.1;
    return Container(
      height: 22,
      padding: const EdgeInsetsDirectional.only(start: 8, end: 10),
      alignment: AlignmentDirectional.center,
      decoration: ShapeDecoration(
        color: primary.withValues(alpha: fillOpacity),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppRingMarker(color: primary, size: 7, borderWidth: 1.5),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.typography.body.xs.copyWith(
              color: primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterColumn {
  const _FooterColumn(this.title, this.links);

  final String title;

  final List<String> links;
}

/// The site footer (`site-shell.svelte`): link columns on the bordered top,
/// the product's mark row, then the giant signature wordmark with its
/// copyright line ([SignatureFooter]).
class _SiteFooter extends StatelessWidget {
  const _SiteFooter({
    required this.siteName,
    required this.symbol,
    required this.tagline,
    required this.columns,
    required this.copyright,
  });

  final String siteName;

  final String symbol;

  final String tagline;

  final List<_FooterColumn> columns;

  final String copyright;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _FooterLinkColumns(columns: columns),
                const SizedBox(height: 40),
                _FooterMarkRow(symbol: symbol, tagline: tagline),
                const SizedBox(height: 24),
                SignatureFooter(name: siteName, copyright: copyright),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The footer's link columns: four across from sm up, two below.
class _FooterLinkColumns extends StatelessWidget {
  const _FooterLinkColumns({required this.columns});

  final List<_FooterColumn> columns;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    Widget column(_FooterColumn column) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          column.title,
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        for (final link in column.links) ...<Widget>[
          Text(link, style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground)),
          const SizedBox(height: 8),
        ],
      ],
    );
    final wide = MediaQuery.sizeOf(context).width >= 640;
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var i = 0; i < columns.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 32),
            Expanded(child: column(columns[i])),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var row = 0; row < columns.length; row += 2) ...<Widget>[
          if (row > 0) const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: column(columns[row])),
              const SizedBox(width: 32),
              Expanded(child: column(columns[row + 1])),
            ],
          ),
        ],
      ],
    );
  }
}

/// The product's mark and tagline, with the working status on the end
/// (`saas-shell.svelte` footerRow).
class _FooterMarkRow extends StatelessWidget {
  const _FooterMarkRow({required this.symbol, required this.tagline});

  final String symbol;

  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final statusColor = theme.brand.success;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppMark(symbol: symbol, squareLabel: 'Product mark'),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                tagline,
                softWrap: true,
                style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppRingMarker(filled: true, color: statusColor),
            const SizedBox(width: 10),
            Text(
              'Every system working',
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Hero pieces
/// ---------------------------------------------------------------------------

/// The wave hero (`wave-hero.svelte`, centered): the words over the wave
/// glow, full height, everything centered, the note row of ring markers
/// under the actions.
class _WaveHero extends StatelessWidget {
  const _WaveHero({
    required this.badgeLead,
    required this.badgeRest,
    required this.title,
    required this.lede,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.notes,
  });

  final String badgeLead;

  final String badgeRest;

  final String title;

  final String lede;

  final String primaryLabel;

  final String secondaryLabel;

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width >= 1024 ? 62.4 : (width >= 640 ? 48.0 : 36.0);
    if (width < 768) {
      // Phone: the wave glow layers are a desktop composition — a scroll
      // view cannot bound their Stack — so the compact hero is the plain
      // centered column.
      return Center(
        child: _Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _HeroBadge(lead: badgeLead, rest: badgeRest),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.02,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.035 * titleSize,
                  color: theme.colors.foreground,
                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  lede,
                  textAlign: TextAlign.center,
                  style: theme.typography.body.lg.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.625,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _SiteButton(label: primaryLabel),
                  _SiteButton(
                    label: secondaryLabel,
                    variant: _SiteButtonVariant.outline,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 6,
                children: <Widget>[for (final note in notes) _HeroNote(note)],
              ),
            ],
          ),
        ),
      );
    }
    // IntrinsicHeight lets the hero grow with its content on desktop-class
    // widths while giving the decorative Stack the bounded constraints a
    // scroll view cannot.
    return IntrinsicHeight(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 820),
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: _WaveGlow()),
            // The site's bottom fade hands the hero to the page color.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 112,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      theme.colors.background.withValues(alpha: 0),
                      theme.colors.background,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: _Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _HeroBadge(lead: badgeLead, rest: badgeRest),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          height: 1.02,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.035 * titleSize,
                          color: theme.colors.foreground,
                          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Text(
                          lede,
                          textAlign: TextAlign.center,
                          style: theme.typography.body.lg.copyWith(
                            color: theme.colors.mutedForeground,
                            height: 1.625,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _SiteButton(label: primaryLabel),
                          _SiteButton(
                            label: secondaryLabel,
                            variant: _SiteButtonVariant.outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final note in notes) _HeroNote(note),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wave glow: two soft horizontal streaks of the primary behind the
/// words, blurred the way the wave shader reads in the captured reference.
class _WaveGlow extends StatelessWidget {
  const _WaveGlow();

  @override
  Widget build(BuildContext context) {
    final primary = context.theme.colors.primary;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FractionallySizedBox(
            heightFactor: 0.38,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 56, sigmaY: 44),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      primary.withValues(alpha: 0.1),
                      primary.withValues(alpha: 0.85),
                      primary.withValues(alpha: 0.25),
                      primary.withValues(alpha: 0.8),
                      primary.withValues(alpha: 0.1),
                    ],
                    stops: const <double>[0, 0.3, 0.55, 0.8, 1],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.35),
            child: FractionallySizedBox(
              widthFactor: 0.72,
              heightFactor: 0.14,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 28),
                child: ColoredBox(color: primary.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero badge pill (`wave-hero.svelte` badge): a bordered pill with the
/// orange dot, the lead word in primary and the rest in muted.
class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.lead, required this.rest});

  final String lead;

  final String rest;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      // Minimum, not fixed: a long badge wraps to a second line at phone
      // widths instead of overflowing.
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: AlignmentDirectional.center,
      decoration: ShapeDecoration(
        color: theme.colors.background.withValues(alpha: 0.6),
        shape: StadiumBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppRingMarker(color: theme.colors.primary, size: 7, borderWidth: 1.5),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                text: lead,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colors.primary,
                  fontWeight: FontWeight.w500,
                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                ),
                children: <InlineSpan>[
                  TextSpan(
                    text: rest,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colors.mutedForeground,
                      fontWeight: FontWeight.w400,
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One note under a hero (`hero-note.svelte`): the orange ring, then 14px
/// muted words.
class _HeroNote extends StatelessWidget {
  const _HeroNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppRingMarker(color: theme.colors.primary),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
        ),
      ],
    );
  }
}

/// The split hero (`wave-hero.svelte` split / `showcase-section` split): the
/// words at the compact size beside the app window staged on a material.
class _SplitHero extends StatelessWidget {
  const _SplitHero();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final titleSize = wide ? 57.6 : (width >= 640 ? 44.0 : 34.0);
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Your whole record,\none window.',
          style: TextStyle(
            fontSize: titleSize,
            height: 1.05,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.035 * titleSize,
            color: theme.colors.foreground,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'What you wrote, how it sounds and what it costs to run — arranged on one canvas that '
          'reads like a notebook page.',
          style: theme.typography.body.lg.copyWith(
            color: theme.colors.mutedForeground,
            height: 1.625,
          ),
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _SiteButton(label: 'Download the demo'),
            _SiteButton(
              label: 'Read the manual',
              variant: _SiteButtonVariant.outline,
            ),
          ],
        ),
      ],
    );
    const stage = _MaterialHeroStage();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: _Container(
        wide: true,
        child: wide
            ? Row(
                children: <Widget>[
                  Expanded(flex: 3, child: words),
                  const SizedBox(width: 40),
                  const Expanded(flex: 5, child: stage),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[words, const SizedBox(height: 40), stage],
              ),
      ),
    );
  }
}

/// The split hero's stage: the app window riding on a brand material, like
/// `showcase-section` ground="material" (`rounded-2xl`, p-4/8/12).
class _MaterialHeroStage extends StatelessWidget {
  const _MaterialHeroStage();

  @override
  Widget build(BuildContext context) {
    final recipe = brandMaterialById('hammered-copper')!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 520,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            BrandMaterialSurface(recipe: recipe),
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: _AppWindow()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The centered inner-page intro (`page-intro.svelte` at the site scale):
/// the grey kicker, the balanced title, the muted lede, all centered.
class _CenteredIntro extends StatelessWidget {
  const _CenteredIntro({required this.kicker, required this.title, required this.lede});

  final String kicker;

  final String title;

  final String lede;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width >= 1024 ? 56.0 : 36.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          kicker,
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            height: 1.05,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.035 * titleSize,
            color: theme.colors.foreground,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            lede,
            textAlign: TextAlign.center,
            style: theme.typography.body.lg.copyWith(
              color: theme.colors.mutedForeground,
              height: 1.625,
            ),
          ),
        ),
      ],
    );
  }
}

/// The site section head (`section.svelte`): the 30px w500 tracking-tight
/// title over the muted 16px intro (gap-3), then the content after the
/// section gap-10. Centered for pages with a centered hero.
class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, required this.child, this.intro, this.center = false});

  final String title;

  final String? intro;

  final bool center;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final head = Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Text(
            title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: 30,
              height: 1.2,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.025 * 30,
              color: theme.colors.foreground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
        ),
        if (intro != null) ...<Widget>[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Text(
              intro!,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
                height: 1.625,
              ),
            ),
          ),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: center ? AlignmentDirectional.center : AlignmentDirectional.centerStart,
          child: head,
        ),
        const SizedBox(height: 40),
        child,
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// The app window (the product screenshot stand-in)
/// ---------------------------------------------------------------------------

class _Customer {
  const _Customer(this.name, this.icon);

  final String name;

  final IconData icon;
}

/// The customer row (`logo-cloud.svelte`): the muted label line, then the
/// names with a line icon each, wrapping and centered.
class _LogoCloud extends StatelessWidget {
  const _LogoCloud({required this.label, required this.customers});

  final String label;

  final List<_Customer> customers;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground)),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 40,
          runSpacing: 20,
          children: <Widget>[
            for (final customer in customers)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(customer.icon, size: 20, color: theme.colors.mutedForeground),
                  const SizedBox(width: 8),
                  Text(
                    customer.name,
                    style: TextStyle(
                      fontSize: 16.4,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.02 * 16.4,
                      color: theme.colors.mutedForeground,
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// The app window (`app-window.svelte`): browser chrome with the address
/// pill, the workspace sidebar, the overview header with the range switch,
/// the three stats, the material sparkline chart and the top-pages rows.
class _AppWindow extends StatelessWidget {
  const _AppWindow();

  static const List<double> _visitors = <double>[
    0.35, 0.5, 0.42, 0.55, 0.48, 0.62, 0.58, 0.7, 0.52, 0.44, 0.6, 0.66, //
    0.5, 0.72, 0.63, 0.57, 0.75, 0.68, 0.55, 0.62, 0.8, 0.7, 0.6, 0.74, 0.66, 0.82,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // A real window: fixed frame height, the content inside scrolls.
    return Container(
      height: 640,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        // Solid, like the kit's material-stage window: this window also rides on
        // a material, and content never sits bare on the metal (BRAND.md s7).
        color: Color.alphaBlend(theme.colors.card.withValues(alpha: 0.4), theme.colors.background),
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _WindowChrome(url: 'app.sightline.io/paperplane/overview'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showSidebar = constraints.maxWidth >= 640;
                const body = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _WindowToolbar(),
                    _WindowStats(),
                    _ChartCard(points: _visitors),
                    _TopPages(),
                  ],
                );
                const scrollable = SingleChildScrollView(child: body);
                if (!showSidebar) {
                  return scrollable;
                }
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(width: 190, child: _WindowSidebar()),
                    Expanded(child: scrollable),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The window's browser chrome: the three dots and the centered address pill.
class _WindowChrome extends StatelessWidget {
  const _WindowChrome({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final dot = BorderSide(color: theme.colors.border);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
        ),
      ),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < 3; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: ShapeDecoration(shape: CircleBorder(side: dot)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: AlignmentDirectional.center,
            decoration: ShapeDecoration(
              shape: StadiumBorder(side: BorderSide(color: theme.colors.border)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(FLucideIcons.lock, size: 11, color: theme.colors.mutedForeground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1,
                      color: theme.colors.mutedForeground,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sidebar: the workspace row, the nav with the active entry, and the
/// tracking status at the foot.
class _WindowSidebar extends StatelessWidget {
  const _WindowSidebar();

  static const List<(IconData, String)> _sidebarEntries = <(IconData, String)>[
    (FLucideIcons.layoutDashboard, 'Overview'),
    (FLucideIcons.filter, 'Funnels'),
    (FLucideIcons.grid2x2, 'Retention'),
    (FLucideIcons.radio, 'Live'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                side: BorderSide(color: theme.colors.border),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Row(
              children: <Widget>[
                const AppMark(symbol: 'Pp', squareLabel: 'Workspace mark', size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paperplane',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final (index, entry) in _sidebarEntries.indexed) ...<Widget>[
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: AlignmentDirectional.centerStart,
              decoration: ShapeDecoration(
                color: index == 0
                    ? theme.colors.foreground.withValues(alpha: 0.08)
                    : Colors.transparent,
                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    entry.$1,
                    size: 14,
                    color: index == 0 ? theme.colors.foreground : theme.colors.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      entry.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.sm.copyWith(
                        color: index == 0 ? theme.colors.foreground : theme.colors.mutedForeground,
                        fontWeight: index == 0 ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              AppRingMarker(filled: true, color: theme.brand.success, size: 7, borderWidth: 1.5),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Tracking is on',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The overview toolbar: the page title and the range switch.
class _WindowToolbar extends StatelessWidget {
  const _WindowToolbar();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
        ),
      ),
      // A Wrap, not a Row+Spacer: at compact widths the range switch wraps
      // under the title instead of overflowing the mock window.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: <Widget>[
          Text(
            'Overview',
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSegmented<String>(
            options: const <AppSegmentOption<String>>[
              (value: '7', label: '7 days', key: null),
              (value: '30', label: '30 days', key: null),
              (value: '90', label: '90 days', key: null),
            ],
            value: '30',
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

/// The three stat cells with their hairline dividers and trend arrows.
class _WindowStats extends StatelessWidget {
  const _WindowStats();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    Widget cell({
      required String label,
      required String value,
      required String trend,
      required bool up,
    }) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: <Widget>[
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.02 * 22,
                    color: theme.colors.foreground,
                    fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        up ? FLucideIcons.arrowUpRight : FLucideIcons.arrowDownRight,
                        size: 12,
                        color: up ? theme.brand.success : theme.brand.destructive,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: theme.typography.body.xs.copyWith(
                          color: up ? theme.brand.success : theme.brand.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final line = BorderSide(color: theme.colors.border, width: theme.style.borderWidth);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        cell(label: 'Visitors', value: '58,074', trend: '16%', up: true),
        Container(width: 1, color: line.color),
        cell(label: 'Signed up', value: '2,381', trend: '19%', up: true),
        Container(width: 1, color: line.color),
        cell(label: 'Came back', value: '41%', trend: '2%', up: false),
      ],
    );
  }
}

/// The visitors chart: the material sparkline under its caption row.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // A Wrap: the legend wraps under the title in narrow cells.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                Text(
                  'Visitors a day',
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _ChartLegendEntry(color: theme.colors.primary, label: 'This period', dashed: false),
                _ChartLegendEntry(
                  color: theme.colors.mutedForeground,
                  label: 'Previous',
                  dashed: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            MaterialSparkline(
              recipe: brandMaterialById('copper-sweep')!,
              points: points,
              extent: 132,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegendEntry extends StatelessWidget {
  const _ChartLegendEntry({required this.color, required this.label, required this.dashed});

  final Color color;

  final String label;

  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lineColor = dashed ? theme.colors.mutedForeground.withValues(alpha: 0.5) : color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14,
          height: 2,
          decoration: ShapeDecoration(color: lineColor, shape: const StadiumBorder()),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground)),
      ],
    );
  }
}

/// The top pages rows: mono paths on soft primary bars, counts on the end.
class _TopPages extends StatelessWidget {
  const _TopPages();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    const rows = <(String, double, String)>[
      ('/pricing', 0.92, '18,584'),
      ('/', 0.78, '15,680'),
      ('/docs/getting-started', 0.54, '10,453'),
      ('/blog/launch-week', 0.3, '6,388'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Top pages',
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          for (final (path, fraction, count) in rows) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 24,
                          alignment: AlignmentDirectional.centerStart,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: theme.colors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1,
                              color: theme.colors.foreground,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    color: theme.colors.mutedForeground,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Landing sections
/// ---------------------------------------------------------------------------

/// The landing bento (`sightline.svelte` grid): 4+2, then 2+2+2, then one
/// full-width tile; stacks to a single column below lg.
class _LandingBento extends StatelessWidget {
  const _LandingBento();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    if (!wide) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _BentoCard(
            title: 'Funnels',
            body:
                'Pick the steps from visit to payment. See how many people make it through each '
                'one, and where the rest leave.',
            visual: _MiniFunnel(),
          ),
          _BentoGap(),
          _BentoCard(
            title: 'Retention',
            body:
                'Of the people who joined each week, how many came back. The darker the square, '
                'the more.',
            visual: _MiniHeat(),
          ),
          _BentoGap(),
          _BentoCard(
            title: 'Live view',
            body: "Who's on your site right now and what they just did.",
            visual: _MiniLive(),
          ),
          _BentoGap(),
          _BentoCard(
            title: 'Goals',
            body: 'Set a number for the month and watch it fill in.',
            visual: _GoalsVisual(),
          ),
          _BentoGap(),
          _BentoCard(
            title: 'Alerts',
            body:
                "An email or a Slack message when something changes that you'd want to know about.",
            visual: _AlertsVisual(),
          ),
          _BentoGap(),
          _BentoCard(
            title: 'Share a chart with a link',
            body:
                'Anyone with the link sees the chart as it is right now, without an account. '
                'Turn the link off whenever you like.',
            visual: _ShareVisual(),
          ),
        ],
      );
    }
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        EqualHeightRow(
          children: <Widget>[
            Expanded(
              flex: 4,
              child: _BentoCard(
                title: 'Funnels',
                body:
                    'Pick the steps from visit to payment. See how many people make it through '
                    'each one, and where the rest leave.',
                visual: _MiniFunnel(),
              ),
            ),
            _BentoGap(),
            Expanded(
              flex: 2,
              child: _BentoCard(
                title: 'Retention',
                body:
                    'Of the people who joined each week, how many came back. The darker the '
                    'square, the more.',
                visual: _MiniHeat(),
              ),
            ),
          ],
        ),
        _BentoGap(),
        EqualHeightRow(
          children: <Widget>[
            Expanded(
              child: _BentoCard(
                title: 'Live view',
                body: "Who's on your site right now and what they just did.",
                visual: _MiniLive(),
              ),
            ),
            _BentoGap(),
            Expanded(
              child: _BentoCard(
                title: 'Goals',
                body: 'Set a number for the month and watch it fill in.',
                visual: _GoalsVisual(),
              ),
            ),
            _BentoGap(),
            Expanded(
              child: _BentoCard(
                title: 'Alerts',
                body:
                    "An email or a Slack message when something changes that you'd want to know "
                    'about.',
                visual: _AlertsVisual(),
              ),
            ),
          ],
        ),
        _BentoGap(),
        _BentoCard(
          title: 'Share a chart with a link',
          body:
              'Anyone with the link sees the chart as it is right now, without an account. Turn '
              'the link off whenever you like.',
          visual: _ShareVisual(),
        ),
      ],
    );
  }
}

class _BentoGap extends StatelessWidget {
  const _BentoGap();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 16, height: 16);
}

/// One bento tile (`outline-card.svelte` + the bento words): the ring at
/// foreground 10%, 24px of air, the 18px title over the 14.4px muted body,
/// the visual pinned to the tile's foot.
class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.title, required this.body, this.visual});

  final String title;

  final String body;

  final Widget? visual;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(
            color: theme.colors.foreground.withValues(alpha: 0.1),
            width: theme.style.borderWidth,
          ),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      // A stretched tile (a matched-height row) pins its visual to the foot
      // with a spacer; at its intrinsic height a fixed gap stands in, so the
      // column never holds a flex child at an unbounded height.
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.01 * 18,
                color: theme.colors.foreground,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(
                fontSize: 14.4,
                height: 1.625,
                color: theme.colors.mutedForeground,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
            if (visual != null) ...<Widget>[
              if (constraints.hasBoundedHeight) const Spacer() else const SizedBox(height: 20),
              visual!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The mini funnel: four bottom-aligned primary bars with their labels.
class _MiniFunnel extends StatelessWidget {
  const _MiniFunnel();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    const steps = <(String, int)>[('Visited', 100), ('Signed up', 40), ('Set up', 22), ('Paid', 9)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 112,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (var i = 0; i < steps.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.bottomCenter,
                    child: Container(
                      height: (steps[i].$2 / 100 * 112).clamp(6.0, 112.0),
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (var i = 0; i < steps.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${steps[i].$1} ',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colors.mutedForeground,
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text: '${steps[i].$2}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colors.foreground,
                          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The mini retention heat: five rows of six squares, the primary deepening
/// with each cohort's return, dashed outlines for the empty cells.
class _MiniHeat extends StatelessWidget {
  const _MiniHeat();

  static const List<List<int>> _rows = <List<int>>[
    <int>[5, 4, 3, 3, 2, 2],
    <int>[5, 4, 3, 2, 2, 0],
    <int>[5, 4, 3, 3, 0, 0],
    <int>[5, 5, 4, 0, 0, 0],
    <int>[5, 4, 0, 0, 0, 0],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    Color? fill(int tone) => switch (tone) {
      5 => theme.colors.primary,
      4 => theme.colors.primary.withValues(alpha: 0.6),
      3 => theme.colors.primary.withValues(alpha: 0.35),
      2 => theme.colors.primary.withValues(alpha: 0.18),
      1 => theme.colors.primary.withValues(alpha: 0.08),
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final row in _rows) ...<Widget>[
          Row(
            children: <Widget>[
              for (var i = 0; i < 6; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: ShapeDecoration(
                        color: fill(row[i]),
                        shape: row[i] == 0
                            ? RoundedSuperellipseBorder(
                                side: BorderSide(
                                  color: theme.colors.border,
                                ),
                              )
                            : RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

/// The live view rows: the marker, the who, the what.
class _MiniLive extends StatelessWidget {
  const _MiniLive();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    const rows = <(String, String, bool)>[
      ('Maya', 'invited 3 teammates', true),
      ('Someone in Austin', 'opened /pricing', false),
      ('Kenji', 'created a project', true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (who, what, good) in rows) ...<Widget>[
          Row(
            children: <Widget>[
              AppRingMarker(
                filled: good,
                color: good ? theme.brand.success : theme.colors.mutedForeground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '$who ',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colors.foreground,
                      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text: what,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colors.mutedForeground,
                          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// The goals visual: the ring gauge and its number.
class _GoalsVisual extends StatelessWidget {
  const _GoalsVisual();

  @override
  Widget build(BuildContext context) {
    return const AppRingGauge(
      value: '72%',
      label: 'of 400 paid sign-ups',
      share: 0.72,
      spacing: 18,
    );
  }
}

/// The alerts visual: the warning notice.
class _AlertsVisual extends StatelessWidget {
  const _AlertsVisual();

  @override
  Widget build(BuildContext context) {
    return const AppNotice(
      title: 'Sign-ups fell 30% on Tuesday, after the 2.4 release.',
      role: AppStatusRole.warning,
    );
  }
}

/// The share visual: the link bar.
class _ShareVisual extends StatelessWidget {
  const _ShareVisual();

  @override
  Widget build(BuildContext context) {
    return const AppLinkBar(
      url: 'https://sightline.io/share/paperplane/pricing-to-team',
      copyLabel: 'Copy link',
    );
  }
}

/// The steps beside the code (`sightline.svelte`): the finished stepper at
/// the left, the two-tab code block at the right, stacked below lg.
class _StepsAndCode extends StatelessWidget {
  const _StepsAndCode();

  @override
  Widget build(BuildContext context) {
    const steps = <AppStepperStep>[
      (
        label: 'Add one line to your site',
        description:
            'Paste the script tag, or install the package if your app is built with React, Vue or '
            'Svelte. Page views start coming in right away.',
      ),
      (
        label: 'Name the moments that matter',
        description:
            'Signed up, invited a teammate, paid. One line each, wherever they happen in your code.',
      ),
      (
        label: 'Read the answers',
        description:
            'Funnels, retention and paths build themselves from those names. No queries, no spreadsheets.',
      ),
    ];
    const code = AppCodeBlock(
      files: <AppCodeFile>[
        AppCodeFile(label: 'Install', source: 'npm install @sightline/web'),
        AppCodeFile(
          label: 'Your app',
          source:
              'import { sightline } from "@sightline/web"\n'
              '\n'
              'sightline.start({ site: "paperplane.app" })\n'
              '\n'
              '// Wherever it happens in your code:\n'
              'sightline.track("Invited a teammate", { plan: "team" })',
        ),
      ],
    );
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final stepper = AppStepper(steps: steps, currentStep: steps.length);
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[stepper, const SizedBox(height: 40), code],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 10, child: stepper),
        const SizedBox(width: 40),
        const Expanded(flex: 11, child: code),
      ],
    );
  }
}

/// The privacy story on the gray band (`band-gray` + `Section`): the title
/// and intro, the ticking checklist in two columns, the outline button.
class _PrivacyBand extends StatelessWidget {
  const _PrivacyBand();

  @override
  Widget build(BuildContext context) {
    const items = <AppCheckItem>[
      (label: "No cookies and nothing stored on visitors' devices", checked: true),
      (label: 'Hosted in the EU, on servers we rent, not share', checked: true),
      (label: "Delete one person's data, or all of it, in one click", checked: true),
      (label: 'Meets GDPR, CCPA and PECR without extra setup', checked: true),
      (label: 'Your data is never sold or used to train anything', checked: true),
    ];
    return BandSurface(
      padding: const EdgeInsets.symmetric(vertical: 96),
      child: _Container(
        child: _SectionHead(
          title: 'Your visitors stay anonymous',
          intro:
              'Sightline counts what people do and never who they are. With no cookies, '
              'fingerprinting or personal data, you can skip the consent banner and your visitors '
              'can skip being followed around.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 640) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: AppCheckList(items: items.sublist(0, 3))),
                        const SizedBox(width: 40),
                        Expanded(child: AppCheckList(items: items.sublist(3))),
                      ],
                    );
                  }
                  return const AppCheckList(items: items);
                },
              ),
              const SizedBox(height: 40),
              const _SiteButton(
                label: 'Read how we handle data',
                variant: _SiteButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quote {
  const _Quote(this.quote, this.name, this.role);

  final String quote;

  final String name;

  final String role;
}

const List<_Quote> _landingQuotes = <_Quote>[
  _Quote(
    'We found out 60% of people left at the card step. We moved it after the first project, and '
        'paid sign-ups doubled in a month.',
    'Ana Duarte',
    'Product lead, Paperplane',
  ),
  _Quote(
    'Our old tool needed an analyst to answer anything. Now the designers open Sightline on '
        'Monday morning and just read it.',
    'Tom Becker',
    'Head of design, Northwind',
  ),
  _Quote(
    'Dropping the cookie banner was worth the switch on its own. Setup took one afternoon.',
    'Rina Okafor',
    'Founder, Fernhill',
  ),
];

/// A row of quote cards (`quote-card.svelte`): the 15.2px quote at 1.7
/// leading over the initials-avatar person row, one card per plan width.
class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quotes});

  final List<_Quote> quotes;

  @override
  Widget build(BuildContext context) {
    Widget card(_Quote quote) => _QuoteCard(quote: quote);
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final mid = MediaQuery.sizeOf(context).width >= 640;
    if (wide) {
      return EqualHeightRow(
        children: <Widget>[
          for (var i = 0; i < quotes.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: card(quotes[i])),
          ],
        ],
      );
    }
    if (mid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          EqualHeightRow(
            children: <Widget>[
              Expanded(child: card(quotes[0])),
              const SizedBox(width: 16),
              Expanded(child: card(quotes[1])),
            ],
          ),
          const SizedBox(height: 16),
          card(quotes[2]),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < quotes.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 16),
          card(quotes[i]),
        ],
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final _Quote quote;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(
            color: theme.colors.foreground.withValues(alpha: 0.1),
            width: theme.style.borderWidth,
          ),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            quote.quote,
            style: TextStyle(
              fontSize: 15.2,
              height: 1.7,
              color: theme.colors.foreground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
          const SizedBox(height: 24),
          _PersonRow(name: quote.name, role: quote.role),
        ],
      ),
    );
  }
}

/// Who said it (`person.svelte`): the initials avatar ring, the name, the
/// role.
class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.name, required this.role, this.size = 32});

  final String name;

  final String role;

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final initials = name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .take(2)
        .join();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          alignment: AlignmentDirectional.center,
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: CircleBorder(
              side: BorderSide(color: theme.colors.foreground.withValues(alpha: 0.15)),
            ),
          ),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: size * 0.34,
              height: 1,
              fontWeight: FontWeight.w500,
              color: theme.colors.foreground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
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
              const SizedBox(height: 2),
              Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colors.mutedForeground,
                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Pricing pieces
/// ---------------------------------------------------------------------------

class _Plan {
  const _Plan(
    this.name,
    this.price,
    this.per,
    this.blurb,
    this.features,
    this.cta, {
    this.pick = false,
  });

  final String name;

  final String price;

  final String per;

  final String blurb;

  final List<String> features;

  final String cta;

  final bool pick;
}

const List<_Plan> _plans = <_Plan>[
  _Plan(
    'Free',
    r'$0',
    'forever',
    'For a side project or a first launch.',
    <String>[
      '10,000 visitors a month',
      'Every chart, one site',
      'Data kept for 6 months',
      'Community support',
    ],
    'Start free',
  ),
  _Plan(
    'Growth',
    r'$39',
    'a month',
    'For a product with real customers.',
    <String>[
      '200,000 visitors a month',
      'Funnels, retention and paths',
      'Alerts by email and Slack',
      'Data kept for 3 years',
    ],
    'Start a free trial',
    pick: true,
  ),
  _Plan(
    'Scale',
    r'$149',
    'a month',
    'For teams that live in the numbers.',
    <String>[
      '2 million visitors a month',
      'Everything in Growth',
      'Single sign-on and roles',
      'Export to your warehouse',
    ],
    'Talk to us',
  ),
];

/// The pricing section (`pricing-plans.svelte`): the billing switch and the
/// three outline cards, the recommended one with the orange ring, the corner
/// rings fingerprint and the filled CTA.
class _PricingPlansSection extends StatefulWidget {
  const _PricingPlansSection({required this.headline, this.compactIntro = false});

  final String? headline;

  final bool compactIntro;

  @override
  State<_PricingPlansSection> createState() => _PricingPlansSectionState();
}

class _PricingPlansSectionState extends State<_PricingPlansSection> {
  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.headline != null) ...<Widget>[
          _SectionHead(
            title: widget.headline!,
            intro:
                'Start free. The price follows your visitors, and every plan includes unlimited people.',
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: 40),
        ],
        AppSegmented<String>(
          options: const <AppSegmentOption<String>>[
            (value: 'monthly', label: 'Monthly', key: null),
            (value: 'yearly', label: 'Yearly, 2 months free', key: null),
          ],
          value: _yearly ? 'yearly' : 'monthly',
          onChanged: (value) => setState(() => _yearly = value == 'yearly'),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final mid = constraints.maxWidth >= 560;
            Widget plan(_Plan plan) => _PlanCard(plan: plan, yearly: _yearly);
            if (wide) {
              return EqualHeightRow(
                children: <Widget>[
                  for (var i = 0; i < _plans.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: plan(_plans[i])),
                  ],
                ],
              );
            }
            final children = <Widget>[
              for (var i = 0; i < _plans.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 16),
                plan(_plans[i]),
              ],
            ];
            if (!mid) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: children,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                EqualHeightRow(
                  children: <Widget>[
                    Expanded(child: plan(_plans[0])),
                    const SizedBox(width: 16),
                    Expanded(child: plan(_plans[1])),
                  ],
                ),
                const SizedBox(height: 16),
                plan(_plans[2]),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One plan card (`pricing-plans.svelte`): the name over the price row, the
/// blurb, the ticking features and the full-width CTA; the recommended plan
/// takes the primary ring at 55% and the corner rings fingerprint.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.yearly});

  final _Plan plan;

  final bool yearly;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Stack(
      children: <Widget>[
        if (plan.pick)
          Positioned(
            top: 0,
            right: 0,
            width: 96,
            height: 96,
            child: CornerRings(
              seed: 'pricing ${plan.name}',
              accentColor: theme.colors.primary,
              quiet: true,
              size: 96,
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                color: plan.pick
                    ? theme.colors.primary.withValues(alpha: 0.55)
                    : theme.colors.foreground.withValues(alpha: 0.1),
                width: theme.style.borderWidth,
              ),
              borderRadius: theme.style.borderRadius.lg,
            ),
          ),
          // A stretched card (a matched-height row) pins its CTA to the foot
          // with a spacer; at its intrinsic height a fixed gap stands in.
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        plan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: theme.colors.foreground,
                          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                        ),
                      ),
                    ),
                    if (plan.pick) const _OrangeTag(label: 'Recommended'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      plan.price,
                      style: TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.04 * 40,
                        color: theme.colors.foreground,
                        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.per,
                      style: TextStyle(
                        fontSize: 14.4,
                        color: theme.colors.mutedForeground,
                        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  plan.blurb,
                  style: TextStyle(
                    fontSize: 14.4,
                    color: theme.colors.mutedForeground,
                    fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                  ),
                ),
                const SizedBox(height: 16),
                AppCheckList(
                  items: <AppCheckItem>[
                    for (final feature in plan.features) (label: feature, checked: true),
                  ],
                ),
                if (constraints.hasBoundedHeight) const Spacer() else const SizedBox(height: 24),
                _SiteButton(
                  label: plan.cta,
                  variant: plan.pick ? _SiteButtonVariant.filled : _SiteButtonVariant.outline,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The plan comparison (`data_table.svelte` boxed): the features against the
/// three plans, the recommended column on the soft primary wash.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  @override
  Widget build(BuildContext context) {
    return const AppDataTable(
      columns: <String>['What you get', 'Free', 'Growth', 'Scale'],
      accentColumn: 2,
      rows: <List<String>>[
        <String>['Visitors a month', '10,000', '200,000', '2,000,000'],
        <String>['Sites', '1', '10', 'Unlimited'],
        <String>['Data kept', '6 months', '3 years', '6 years'],
        <String>['Funnels, retention, paths', 'Yes', 'Yes', 'Yes'],
        <String>['Alerts by email and Slack', '—', 'Yes', 'Yes'],
        <String>['Single sign-on and roles', '—', '—', 'Yes'],
        <String>['Export to your warehouse', '—', '—', 'Yes'],
        <String>['Support', 'Community', 'Email', 'Dedicated'],
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem(this.question, this.answer, [this.topic]);

  final String question;

  final String answer;

  final String? topic;
}

const List<_FaqItem> _faqItems = <_FaqItem>[
  _FaqItem(
    'Do I need a cookie banner?',
    "No. Sightline doesn't use cookies or store anything on your visitors' devices, so there's "
        'nothing to ask permission for in the EU or the UK.',
    'Privacy',
  ),
  _FaqItem(
    'Will it slow my site down?',
    "The script is 4 kB and loads after your page does. People won't notice it's there.",
    'Speed',
  ),
  _FaqItem(
    'Can I bring my old data?',
    'Yes. Upload an export from Google Analytics or Mixpanel and Sightline adds it to your '
        'charts, so your history stays in one place.',
    'Importing',
  ),
  _FaqItem(
    'What happens when I go over my plan?',
    'Nothing breaks. We keep counting and send you an email. If it happens two months in a row, '
        "we'll suggest the next plan.",
    'Billing',
  ),
  _FaqItem(
    'Who can see my data?',
    'Only the people you invite. We never sell it, share it, or use it to train anything.',
    'Privacy',
  ),
  _FaqItem(
    'Can I cancel any time?',
    'Yes, from the settings page, in two clicks. You can download everything before you go.',
    'Billing',
  ),
];

/// ---------------------------------------------------------------------------
/// Product-page sections
/// ---------------------------------------------------------------------------

/// The feature bento: icon tiles with mono stats, one orange tile with the
/// mini bars, one material-cover card, stacked to one column below md.
class _FeatureBento extends StatelessWidget {
  const _FeatureBento();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final iconTiles = <Widget>[
      const _IconStatTile(
        icon: FLucideIcons.workflow,
        title: 'Patch anything',
        body: 'Every module is a card on the canvas. Rewire the chain without losing a take.',
        stat: '48',
        statLabel: 'modules in the starter rack',
      ),
      const _IconStatTile(
        icon: FLucideIcons.timer,
        title: 'Bounces in seconds',
        body: 'The render engine prints a full track before the kettle boils.',
        stat: '11 s',
        statLabel: 'for a four-minute bounce',
      ),
      const _IconStatTile(
        icon: FLucideIcons.globe,
        title: 'Runs where you are',
        body: 'macOS, Windows and Linux from one project folder, no install step.',
        stat: '3',
        statLabel: 'platforms, one license file',
      ),
    ];
    final visualTiles = <Widget>[
      const _OrangeTile(
        title: 'The mixer reads like a notebook',
        body: 'Levels, sends and returns on one page. No hidden panes, no nested menus.',
      ),
      const _MaterialCoverTile(
        title: 'Instruments you can read',
        body: 'Each patch is one small text file. Diff it, version it, share it.',
      ),
    ];
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < iconTiles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 16),
            iconTiles[i],
          ],
          const SizedBox(height: 16),
          visualTiles[0],
          const SizedBox(height: 16),
          visualTiles[1],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        EqualHeightRow(
          children: <Widget>[
            for (var i = 0; i < iconTiles.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: iconTiles[i]),
            ],
          ],
        ),
        const SizedBox(height: 16),
        EqualHeightRow(
          children: <Widget>[
            Expanded(child: visualTiles[0]),
            const SizedBox(width: 16),
            Expanded(child: visualTiles[1]),
          ],
        ),
      ],
    );
  }
}

/// One feature tile: the icon tile up top, the words, the mono stat at the
/// foot (`feature-bento.svelte` outline tone).
class _IconStatTile extends StatelessWidget {
  const _IconStatTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.stat,
    required this.statLabel,
  });

  final IconData icon;

  final String title;

  final String body;

  final String stat;

  final String statLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(
            color: theme.colors.foreground.withValues(alpha: 0.1),
            width: theme.style.borderWidth,
          ),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIconTile(icon: icon),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.01 * 18,
                color: theme.colors.foreground,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(
                fontSize: 14.4,
                height: 1.625,
                color: theme.colors.mutedForeground,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
            if (constraints.hasBoundedHeight) const Spacer() else const SizedBox(height: 20),
            Text(
              stat,
              style: TextStyle(
                fontSize: 40,
                height: 1,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.03 * 40,
                color: theme.colors.foreground,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statLabel,
              style: TextStyle(
                fontSize: 13,
                color: theme.colors.mutedForeground,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The orange feature tile (`feature-bento.svelte` orange tone): solid
/// oxide, on-orange words, mini bars at the foot.
class _OrangeTile extends StatelessWidget {
  const _OrangeTile({required this.title, required this.body});

  final String title;

  final String body;

  @override
  Widget build(BuildContext context) {
    final brand = context.theme.brand;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: brand.oxide, borderRadius: BorderRadius.circular(12)),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.01 * 18,
                color: brand.onOrange,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: 14.4,
                  height: 1.625,
                  color: brand.onOrange.withValues(alpha: 0.75),
                  fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                ),
              ),
            ),
            if (constraints.hasBoundedHeight) const Spacer() else const SizedBox(height: 20),
            const _MiniBarsOnOrange(),
          ],
        ),
      ),
    );
  }
}

/// The orange tile's mini bars: on-orange bars walking down like a level
/// read-out, per the feature-bento "a-speed" reference.
class _MiniBarsOnOrange extends StatelessWidget {
  const _MiniBarsOnOrange();

  @override
  Widget build(BuildContext context) {
    final brand = context.theme.brand;
    const bars = <double>[0.9, 0.45, 0.7, 0.3, 0.55, 0.85, 0.4, 0.65, 0.5, 0.95, 0.35, 0.6];
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (var i = 0; i < bars.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: bars[i] * 72,
                decoration: BoxDecoration(
                  color: brand.onOrange.withValues(alpha: i.isEven ? 0.9 : 0.45),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The material-cover feature tile (`feature-bento.svelte` material tone)
/// built from the kit's [MaterialCard] with a fixed cover band.
class _MaterialCoverTile extends StatelessWidget {
  const _MaterialCoverTile({required this.title, required this.body});

  final String title;

  final String body;

  @override
  Widget build(BuildContext context) {
    return MaterialCard(
      recipe: brandMaterialById('folded-foil')!,
      bandExtent: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.01 * 18,
              color: context.theme.colors.foreground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 14.4,
              height: 1.625,
              color: context.theme.colors.mutedForeground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

/// The showcase over the rings (`showcase-section` ground="rings"): the
/// centered words, then the window staged wide over the hero rings, with two
/// glass notes pointing at it from md up.
class _ShowcaseOverRings extends StatelessWidget {
  const _ShowcaseOverRings();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    Widget stage = _Container(
      wide: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: wide ? 560 : 460,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // The rings bleed off the right edge behind the window.
              const Positioned(
                top: 0,
                bottom: 0,
                right: -80,
                width: 720,
                child: Center(child: _GalleryHeroRings()),
              ),
              Padding(
                padding: EdgeInsets.all(wide ? 48 : 20),
                child: const Center(child: _AppWindow()),
              ),
            ],
          ),
        ),
      ),
    );
    if (wide) {
      stage = Stack(
        children: <Widget>[
          stage,
          const Positioned(left: 72, top: 96, child: _GlassNote(text: 'One canvas, every layer')),
          const Positioned(
            right: 88,
            bottom: 88,
            child: _GlassNote(text: 'Ships as a folder of files'),
          ),
        ],
      );
    }
    return _Container(
      wide: true,
      child: _SectionHead(
        title: 'One screen, start to finish',
        intro:
            'The arrangement, the mix and the render queue on one canvas — this is the whole '
            'product, not a screenshot of a tab.',
        center: true,
        child: stage,
      ),
    );
  }
}

class _GalleryHeroRings extends StatelessWidget {
  const _GalleryHeroRings();

  @override
  Widget build(BuildContext context) {
    // The rings picture resolved through the kit's hero recipe via the
    // BrandRings widget would run its ticker; the still preset keeps the
    // dump deterministic.
    return const BrandRings(seed: 'oxiwake');
  }
}

/// One glass note pill floating over the stage (`showcase-section` notes).
class _GlassNote extends StatelessWidget {
  const _GlassNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      variant: GlassVariant.smoke,
      radius: BorderRadius.circular(100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: context.theme.colors.foreground,
          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
        ),
      ),
    );
  }
}

/// The numbers on the gray band (`band-section` variant="stats"): the values
/// at 56px w500 tight, labels under, hairline dividers between.
class _NumbersBand extends StatelessWidget {
  const _NumbersBand();

  @override
  Widget build(BuildContext context) {
    const stats = <(String, String)>[
      ('12k', 'studios run Oxiwake daily'),
      ('11 s', 'average full-track bounce'),
      ('340', 'instruments in the library'),
      ('1 file', 'to move the whole license'),
    ];
    return BandSurface(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: _Container(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < stats.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 32),
                    _BigStat(value: stats[i].$1, label: stats[i].$2),
                  ],
                ],
              );
            }
            return EqualHeightRow(
              children: <Widget>[
                for (var i = 0; i < stats.length; i++) ...<Widget>[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Container(width: 1, color: context.theme.colors.border),
                    ),
                  Expanded(
                    child: _BigStat(value: stats[i].$1, label: stats[i].$2),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});

  final String value;

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: TextStyle(
            fontSize: 56,
            height: 1,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.045 * 56,
            color: theme.colors.foreground,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            fontFamily: DefaultTextStyle.of(context).style.fontFamily,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.mutedForeground,
            height: 1.625,
          ),
        ),
      ],
    );
  }
}

/// The big quote (`band-section` variant="quote"): the 33.6px balanced
/// sentence over the large person row.
class _BigQuote extends StatelessWidget {
  const _BigQuote({required this.quote, required this.name, required this.role});

  final String quote;

  final String name;

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: Text(
            quote,
            style: TextStyle(
              fontSize: 33.6,
              height: 1.35,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.02 * 33.6,
              color: theme.colors.foreground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
        ),
        const SizedBox(height: 32),
        _PersonRow(name: name, role: role, size: 40),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Company-page sections
/// ---------------------------------------------------------------------------

/// The values tiles: three outline cards with the icon tiles, one rule per
/// project in the family.
class _ValuesRow extends StatelessWidget {
  const _ValuesRow();

  @override
  Widget build(BuildContext context) {
    const values = <(IconData, String, String)>[
      (
        FLucideIcons.lock,
        'Your files stay yours',
        'Everything reads and writes plain folders. No accounts, no lock-in, no export step.',
      ),
      (
        FLucideIcons.zap,
        'Fast is a feature',
        'A tool that opens in a second gets used. Every release has a budget and we keep it.',
      ),
      (
        FLucideIcons.gem,
        'Buy it once',
        'Licenses are files, not subscriptions. When we ship a paid thing, you own it.',
      ),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    Widget card((IconData, String, String) value) =>
        _ValueCard(icon: value.$1, title: value.$2, body: value.$3);
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < values.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 16),
            card(values[i]),
          ],
        ],
      );
    }
    return EqualHeightRow(
      children: <Widget>[
        for (var i = 0; i < values.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: card(values[i])),
        ],
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.icon, required this.title, required this.body});

  final IconData icon;

  final String title;

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(
            color: theme.colors.foreground.withValues(alpha: 0.1),
            width: theme.style.borderWidth,
          ),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconTile(icon: icon),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.01 * 18,
              color: theme.colors.foreground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 14.4,
              height: 1.625,
              color: theme.colors.mutedForeground,
              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

/// The quote on the gray band (`band-section` quote, tone="gray").
class _GrayQuoteBand extends StatelessWidget {
  const _GrayQuoteBand();

  @override
  Widget build(BuildContext context) {
    return const BandSurface(
      padding: EdgeInsets.symmetric(vertical: 96),
      child: _Container(
        child: _BigQuote(
          quote:
              'Software should end when you close the window. Nothing of yours should keep running '
              'in a room you have never seen.',
          name: 'Ines Caldwell',
          role: 'Founder, hmziq',
        ),
      ),
    );
  }
}

const List<({String name, String role, String bio})> _team =
    <({String name, String role, String bio})>[
      (
        name: 'Ines Caldwell',
        role: 'Founder',
        bio: 'Started the family with a note app that refused to need an account.',
      ),
      (
        name: 'Ravi Menon',
        role: 'Systems',
        bio: 'Keeps every tool fast on the oldest machine in the room.',
      ),
      (
        name: 'Marta Kowalczyk',
        role: 'Design',
        bio: 'Draws the surfaces once and refuses to draw them twice.',
      ),
      (
        name: 'Jonas Ehiert',
        role: 'Docs',
        bio: 'Writes the manuals people actually read, then reads the issues.',
      ),
      (
        name: 'Aoife Brennan',
        role: 'Engineering',
        bio: 'Ships the render engines and the boring installers.',
      ),
      (
        name: 'Kenji Watanabe',
        role: 'Support',
        bio: 'Answers every ticket, then files what the answer teaches us.',
      ),
    ];

/// The team grid: the kit's person cards, three across from lg.
class _TeamGrid extends StatelessWidget {
  const _TeamGrid();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final mid = MediaQuery.sizeOf(context).width >= 640;
    Widget card(({String name, String role, String bio}) person) => AppPersonCard(
      name: person.name,
      role: person.role,
      bio: person.bio,
      links: const <String>['GitHub', 'X'],
    );
    if (wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var row = 0; row < 2; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: 16),
            EqualHeightRow(
              children: <Widget>[
                for (var col = 0; col < 3; col++) ...<Widget>[
                  if (col > 0) const SizedBox(width: 16),
                  Expanded(child: card(_team[row * 3 + col])),
                ],
              ],
            ),
          ],
        ],
      );
    }
    if (mid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var row = 0; row < 3; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: 16),
            EqualHeightRow(
              children: <Widget>[
                Expanded(child: card(_team[row * 2])),
                const SizedBox(width: 16),
                Expanded(child: card(_team[row * 2 + 1])),
              ],
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < _team.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 16),
          card(_team[i]),
        ],
      ],
    );
  }
}

const List<_Quote> _wallQuotes = <_Quote>[
  _Quote(
    'Search is instant and I stopped bookmarking things. I just ask my notes.',
    'Ines Caldwell',
    'Product designer, Fieldnote',
  ),
  _Quote(
    'It replaced three apps on my machine, and the files are still plain markdown I could have '
        'written by hand.',
    'Ravi Menon',
    'Engineering manager, Copperleaf',
  ),
  _Quote(
    'I write on the train with the radio off. Nothing asks for the network.',
    'Marta Kowalczyk',
    'Engineering lead, Halden Labs',
  ),
  _Quote(
    'The export is boring in the best way: one folder, clean files, done.',
    'Jonas Ehiert',
    'Developer, Bramble Type',
  ),
  _Quote(
    'Backlinks finally made sense to me here. They are just links, and they are mine.',
    'Aoife Brennan',
    'Technical writer, Lowtide',
  ),
  _Quote(
    'Setup took a minute. I dragged the folder in and everything from the old app was already '
        'there.',
    'Kenji Watanabe',
    'Indie developer',
  ),
];

/// The testimonial wall, grid variant (`testimonial-wall.svelte`): three
/// quote cards across from lg, two from sm.
class _TestimonialWall extends StatelessWidget {
  const _TestimonialWall();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final mid = MediaQuery.sizeOf(context).width >= 640;
    Widget card(_Quote quote) => _QuoteCard(quote: quote);
    if (wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var row = 0; row < 2; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: 16),
            EqualHeightRow(
              children: <Widget>[
                for (var col = 0; col < 3; col++) ...<Widget>[
                  if (col > 0) const SizedBox(width: 16),
                  Expanded(child: card(_wallQuotes[row * 3 + col])),
                ],
              ],
            ),
          ],
        ],
      );
    }
    if (mid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var row = 0; row < 3; row++) ...<Widget>[
            if (row > 0) const SizedBox(height: 16),
            EqualHeightRow(
              children: <Widget>[
                Expanded(child: card(_wallQuotes[row * 2])),
                const SizedBox(width: 16),
                Expanded(child: card(_wallQuotes[row * 2 + 1])),
              ],
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < _wallQuotes.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 16),
          card(_wallQuotes[i]),
        ],
      ],
    );
  }
}

/// The works-alongside row: the bundled Simple Icons marks of the tools the
/// family keeps files compatible with, in muted grey.
class _WorksAlongside extends StatelessWidget {
  const _WorksAlongside();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Works alongside',
          style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
        ),
        const SizedBox(height: 24),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 40,
          runSpacing: 20,
          children: <Widget>[
            BrandIcon(name: 'github'),
            BrandIcon(name: 'gitlab'),
            BrandIcon(name: 'figma'),
            BrandIcon(name: 'slack'),
            BrandIcon(name: 'google'),
            BrandIcon(name: 'apple'),
          ],
        ),
      ],
    );
  }
}
