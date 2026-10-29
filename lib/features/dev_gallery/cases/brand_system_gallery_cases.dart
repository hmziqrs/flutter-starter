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
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/brand/app_notice.dart';
import 'package:starter/shared/widgets/brand/app_ring_gauge.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';

/// The brand-system stories: every brand widget, tone and anti-pattern in one
/// dev-gallery screen (BRAND.md section 9, "Before it ships": every component
/// ships with a story).
///
/// Dev-only surface, so the labels and copy are literal English.
enum BrandSystemGalleryKind {
  wordmark,
  markers,
  statusTags,
  iconTiles,
  notices,
  ringGauges,
  surfaces,
  palette,
  type,
}

/// Builds the "Brand system" gallery cases, one per brand widget or rule.
List<GalleryCase> buildBrandSystemGalleryCases() {
  return <GalleryCase>[
    for (final kind in BrandSystemGalleryKind.values)
      TypedGalleryCase<BrandSystemGalleryKind>(
        id: 'brandSystem.${kind.name}',
        screenId: 'brandSystem',
        screenLabelBuilder: (_) => 'Brand system',
        caseLabelBuilder: (_) => _caseLabel(kind),
        stateFactory: (_) => kind,
        pageFactory: (_, state) => _BrandSystemPreview(kind: state),
      ),
  ];
}

String _caseLabel(BrandSystemGalleryKind kind) => switch (kind) {
  BrandSystemGalleryKind.wordmark => 'Wordmark',
  BrandSystemGalleryKind.markers => 'Ring markers',
  BrandSystemGalleryKind.statusTags => 'Status tags',
  BrandSystemGalleryKind.iconTiles => 'Icon tiles',
  BrandSystemGalleryKind.notices => 'Notices',
  BrandSystemGalleryKind.ringGauges => 'Ring gauges',
  BrandSystemGalleryKind.surfaces => 'Surfaces',
  BrandSystemGalleryKind.palette => 'Palette',
  BrandSystemGalleryKind.type => 'Type specimen',
};

String _caseDescription(BrandSystemGalleryKind kind) => switch (kind) {
  BrandSystemGalleryKind.wordmark => 'The name in Onest 600 with a trailing orange square.',
  BrandSystemGalleryKind.markers => 'A hollow ring for bullets and live status; filled means on.',
  BrandSystemGalleryKind.statusTags => 'Soft pills in the five status roles.',
  BrandSystemGalleryKind.iconTiles => 'Outline tiles; a tone fills one softly in its own color.',
  BrandSystemGalleryKind.notices => 'A thin line and an icon in the note color, no fill.',
  BrandSystemGalleryKind.ringGauges => 'A 72px ring with a value and its label.',
  BrandSystemGalleryKind.surfaces =>
    'Cards in the page are outlines. Grey fill is the anti-pattern.',
  BrandSystemGalleryKind.palette => 'Every AppBrandColors token with its hex in each mode.',
  BrandSystemGalleryKind.type => 'Onest for reading, JetBrains Mono for machine values.',
};

class _BrandSystemPreview extends ConsumerWidget {
  const _BrandSystemPreview({required this.kind});

  final BrandSystemGalleryKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    // The brand's own primary is oxide orange (BRAND.md s4: --primary points
    // at --orange), so the showcase pins the brand accent no matter which
    // accent the gallery environment picked; otherwise the ring-gauge arc and
    // the default icon tile draw in the neutral accent's grey and the orange
    // signature goes undemonstrated.
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
              BrandSystemGalleryKind.wordmark => const _WordmarkStory(),
              BrandSystemGalleryKind.markers => const _MarkerStory(),
              BrandSystemGalleryKind.statusTags => const _StatusTagStory(),
              BrandSystemGalleryKind.iconTiles => const _IconTileStory(),
              BrandSystemGalleryKind.notices => const _NoticeStory(),
              BrandSystemGalleryKind.ringGauges => const _RingGaugeStory(),
              BrandSystemGalleryKind.surfaces => const _SurfaceStory(),
              BrandSystemGalleryKind.palette => const _PaletteStory(),
              BrandSystemGalleryKind.type => const _TypeStory(),
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
    // Page title: `text-2xl font-medium tracking-tight` (APP-BLOCKS.md app
    // type scale); Tailwind's `tracking-tight` is -0.025em.
    final titleStyle = theme.typography.display.xl.copyWith(
      color: theme.colors.foreground,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.025 * (theme.typography.display.xl.fontSize ?? 24),
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

class _WordmarkStory extends StatelessWidget {
  const _WordmarkStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppWordmark(name: 'starter', makerLine: 'by hmziq'),
        SizedBox(height: context.spacing.xs),
        const _Caption('Default size: square and maker line.'),
        SizedBox(height: context.spacing.lg),
        const AppWordmark(name: 'starter', showSquare: false),
        SizedBox(height: context.spacing.xs),
        const _Caption('Without the square.'),
        SizedBox(height: context.spacing.lg),
        const AppWordmark(name: 'starter', fontSize: 32),
        SizedBox(height: context.spacing.xs),
        const _Caption('Sized by font size: the square scales with it.'),
      ],
    );
  }
}

class _MarkerStory extends StatelessWidget {
  const _MarkerStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final body = theme.typography.body.sm.copyWith(color: theme.colors.foreground);
    final mutedBody = body.copyWith(color: theme.colors.mutedForeground);
    // The brand pairs the marker with its label at gap-2.5 (10px;
    // marker.stories.svelte), which sits between the spacing tokens.
    const markerGap = SizedBox(width: 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            AppRingMarker(color: theme.colors.primary),
            markerGap,
            Expanded(child: Text('Hollow at rest, taking the color you give it', style: mutedBody)),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        Row(
          children: <Widget>[
            AppRingMarker(color: theme.colors.primary, filled: true),
            markerGap,
            Expanded(child: Text('Filled: on, open, done or selected', style: body)),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        Row(
          children: <Widget>[
            AppRingMarker(color: theme.brand.success, filled: true),
            markerGap,
            Expanded(
              child: Text('Takes any token color when the color means something', style: body),
            ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colors.mutedForeground,
              ),
            ),
            markerGap,
            Expanded(
              child: Text(
                'Wrong: a solid dot. Bullets are hollow rings, filled only '
                'for on, open, done or selected.',
                style: body.copyWith(color: theme.colors.mutedForeground),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusTagStory extends StatelessWidget {
  const _StatusTagStory();

  @override
  Widget build(BuildContext context) {
    const roles = <(AppStatusRole, String)>[
      (AppStatusRole.neutral, 'Planned'),
      (AppStatusRole.success, 'Shipped'),
      (AppStatusRole.warning, 'In progress'),
      (AppStatusRole.info, 'Tip'),
      (AppStatusRole.destructive, 'Failed'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _SectionTitle(title: 'Every role'),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: <Widget>[
            for (final (role, label) in roles) AppStatusTag(label: label, role: role),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _SectionTitle(title: 'With the marker, for live states'),
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: <Widget>[
            for (final (role, label) in roles)
              AppStatusTag(label: label, role: role, showMarker: true),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption('Role color at 10% fill (20% in dark) with role-colored text.'),
      ],
    );
  }
}

class _IconTileStory extends StatelessWidget {
  const _IconTileStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    final tiles = <(String, IconData, Color?)>[
      ('primary', FLucideIcons.download, null),
      ('oxide', FLucideIcons.squareTerminal, brand.oxide),
      ('red', FLucideIcons.octagonAlert, brand.red),
      ('yellow', FLucideIcons.triangleAlert, brand.yellow),
      ('green', FLucideIcons.circleCheck, brand.green),
      ('teal', FLucideIcons.tag, brand.teal),
      ('blue', FLucideIcons.info, brand.blue),
      ('purple', FLucideIcons.hash, brand.purple),
      ('pink', FLucideIcons.penLine, brand.pink),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: context.spacing.lg,
          runSpacing: context.spacing.lg,
          children: <Widget>[
            for (final (name, icon, tone) in tiles)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppIconTile(icon: icon, tone: tone),
                  SizedBox(height: context.spacing.xs),
                  _MonoText(name),
                ],
              ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption(
          'Outline tile with the icon in primary; a tone fills it softly with '
          'one color at 10% (20% in dark).',
        ),
      ],
    );
  }
}

class _NoticeStory extends StatelessWidget {
  const _NoticeStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Info is the default role.
        const AppNotice(
          title: 'New in this build',
          body: 'The environment controls moved to the toolbar.',
        ),
        SizedBox(height: context.spacing.lg),
        const AppNotice(
          role: AppStatusRole.success,
          title: 'Draft saved',
          body: 'Your changes are on this device.',
        ),
        SizedBox(height: context.spacing.lg),
        const AppNotice(
          role: AppStatusRole.warning,
          title: 'Storage is nearly full',
          body: 'Remove a few downloads to free up space.',
        ),
        SizedBox(height: context.spacing.lg),
        const AppNotice(
          role: AppStatusRole.destructive,
          title: "Couldn't save your changes",
          body: 'Check your connection and try again.',
        ),
      ],
    );
  }
}

class _RingGaugeStory extends StatelessWidget {
  const _RingGaugeStory();

  @override
  Widget build(BuildContext context) {
    // The brand's Gauges story (rings.stories.svelte): a full ring, a 90%
    // share, and five segments — 1 draws full, 0.9 nearly, 5 splits.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceAround,
          spacing: context.spacing.lg,
          runSpacing: context.spacing.lg,
          children: const <Widget>[
            AppRingGauge(share: 1, value: '100%', label: 'Open source'),
            AppRingGauge(share: 0.9, value: '90%+', label: 'Tests that pass'),
            AppRingGauge(count: 5, value: '5', label: 'Rounds of review'),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption('A full ring, a 90% arc over its track, and five segments drawn by count.'),
      ],
    );
  }
}

class _SurfaceStory extends StatelessWidget {
  const _SurfaceStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Expanded(
              child: _SurfaceColumn(
                caption: 'Correct: a thin line, transparent fill, no shadow.',
                card: _SurfaceCard(),
              ),
            ),
            SizedBox(width: context.spacing.lg),
            const Expanded(
              child: _SurfaceColumn(
                caption: 'Wrong: grey fill on a card sitting in the page.',
                card: _SurfaceCard(greyFilled: true),
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.lg),
        const _Caption('Grey fill belongs to hover, selection and floating overlays.'),
      ],
    );
  }
}

class _SurfaceColumn extends StatelessWidget {
  const _SurfaceColumn({required this.card, required this.caption});

  final Widget card;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        card,
        SizedBox(height: context.spacing.sm),
        _Caption(caption),
      ],
    );
  }
}

/// The outline card every page surface uses, plus the grey-filled
/// anti-example next to it (BRAND.md s13: no grey-filled cards in the page).
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({this.greyFilled = false});

  final bool greyFilled;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: EdgeInsets.all(context.spacing.lg),
      decoration: ShapeDecoration(
        color: greyFilled ? theme.colors.muted : Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          // The card recipe's rounded-xl (--radius + 4 = 14px), AppCard's lg.
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Outline card',
            style: theme.typography.body.md.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          Text(
            'A thin line and no fill. Hover changes color only.',
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _PaletteStory extends StatelessWidget {
  const _PaletteStory();

  @override
  Widget build(BuildContext context) {
    final brand = context.theme.brand;
    final swatches = <(String, Color, String, String)>[
      ('oxide', brand.oxide, '#F38230', '#AA530A'),
      ('red', brand.red, '#FF6467', '#CD1622'),
      ('yellow', brand.yellow, '#E7B643', '#906106'),
      ('green', brand.green, '#5DC879', '#017B37'),
      ('teal', brand.teal, '#36C6B8', '#04786E'),
      ('blue', brand.blue, '#5FA7FF', '#0069CD'),
      ('purple', brand.purple, '#B58BF9', '#864AD2'),
      ('pink', brand.pink, '#F079B6', '#BC3181'),
      ('onOrange', brand.onOrange, '#0A0A0A', '#FFFFFF'),
      ('line', brand.line, '#FAFAFA at 22%', '#0A0A0A at 22%'),
      ('markSquare', brand.markSquare, '#F38230', '#F38230'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (name, color, darkHex, lightHex) in swatches) ...<Widget>[
          _ColorRow(name: name, color: color, darkHex: darkHex, lightHex: lightHex),
          SizedBox(height: context.spacing.md),
        ],
        const _Caption('The swatch resolves the token for this mode; the label lists both modes.'),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.name,
    required this.color,
    required this.darkHex,
    required this.lightHex,
  });

  final String name;
  final Color color;
  final String darkHex;
  final String lightHex;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: <Widget>[
        Container(
          width: 20,
          height: 20,
          decoration: ShapeDecoration(
            color: color,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
        ),
        SizedBox(width: context.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _MonoText(name),
              SizedBox(height: context.spacing.xs),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(text: 'Dark '),
                    _hexSpan(context, darkHex),
                    const TextSpan(text: ' · light '),
                    _hexSpan(context, lightHex),
                  ],
                ),
                style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextSpan _hexSpan(BuildContext context, String hex) {
    final theme = context.theme;
    return TextSpan(
      text: hex,
      style: theme.typography.body.sm.copyWith(
        color: theme.colors.mutedForeground,
        fontFamily: 'JetBrains Mono',
      ),
    );
  }
}

class _TypeStory extends StatelessWidget {
  const _TypeStory();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Page title: `text-2xl font-medium tracking-tight` (APP-BLOCKS.md app
    // type scale); Tailwind's `tracking-tight` is -0.025em.
    final pageTitle = theme.typography.display.xl.copyWith(
      color: theme.colors.foreground,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.025 * (theme.typography.display.xl.fontSize ?? 24),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Page title at 24, weight 500', style: pageTitle),
        SizedBox(height: context.spacing.xs),
        const _Caption('Onest 500, tight tracking.'),
        SizedBox(height: context.spacing.lg),
        Text(
          'Onest 500 sets headings.',
          style: theme.typography.body.md.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        const _Caption('Section headings at 16.'),
        SizedBox(height: context.spacing.lg),
        Text(
          'Onest 400 carries body text. One idea per sentence.',
          style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
        ),
        SizedBox(height: context.spacing.xs),
        const _Caption('Body at 14. Never heavier than 600.'),
        SizedBox(height: context.spacing.lg),
        Text(
          'Onest 600 belongs to the wordmark.',
          style: theme.typography.body.lg.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        const _Caption('The heaviest weight in the brand.'),
        SizedBox(height: context.spacing.lg),
        Text(
          'flutter analyze --fatal-infos',
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.foreground,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        SizedBox(height: context.spacing.xs),
        const _Caption('JetBrains Mono 400, for code and machine values only.'),
      ],
    );
  }
}

/// Token names and hex values are machine values, so they run in JetBrains
/// Mono (BRAND.md s5: mono never sets headings or labels people read).
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
