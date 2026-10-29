import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
import 'package:starter/shared/widgets/marks/app_mark.dart';

/// What kind of change a release group carries, with the one color the kind
/// keeps everywhere (kind-tag.svelte: Added green, Changed blue, Fixed
/// yellow).
enum AppReleaseChangeKind {
  added(AppStatusRole.success, 'Added'),
  changed(AppStatusRole.info, 'Changed'),
  fixed(AppStatusRole.warning, 'Fixed');

  const AppReleaseChangeKind(this.role, this.label);

  /// The status role whose soft fill and text color the kind tag borrows.
  final AppStatusRole role;

  /// The tag's word, capitalized like the kit's.
  final String label;
}

/// One group of a release's notes: the `kind` of change and its `lines`, a
/// few words each.
typedef AppReleaseGroup = ({AppReleaseChangeKind kind, List<String> lines});

/// One package manager's update command.
typedef AppReleaseInstall = ({String manager, String command});

/// One release (release-card.svelte): the version large in mono, the product
/// mark line and the date (plus the material "Latest" tag when this is the
/// newest one) in the header, the changes grouped by kind — a few lines each
/// and the rest counted — and the update command per package manager.
class AppReleaseCard extends StatefulWidget {
  const AppReleaseCard({
    required this.version,
    required this.date,
    required this.groups,
    this.product,
    this.symbol,
    this.symbolLabel,
    this.latestLabel,
    this.installs = const <AppReleaseInstall>[],
    this.notesLabel,
    this.visibleLines = 2,
    super.key,
  });

  /// The release version, e.g. `0.12.0` — a machine value, so it runs large
  /// in mono.
  final String version;

  /// The release date, in the caller's words.
  final String date;

  /// The changes by kind, in order; each group shows its [visibleLines]
  /// first lines and counts the rest ("and 2 more").
  final List<AppReleaseGroup> groups;

  /// The product's name, beside the mark; without it no mark line shows.
  final String? product;

  /// The product's two-letter mark symbol, e.g. `Cm`.
  final String? symbol;

  /// The mark's accessibility label; required when [symbol] is set.
  final String? symbolLabel;

  /// When set (e.g. `Latest`), the material tag names this the newest
  /// release in the header's end corner.
  final String? latestLabel;

  /// Update commands, one per package manager; the first sits in the inset,
  /// the rest behind the segmented picker. Without any, no footer shows
  /// unless [notesLabel] is set.
  final List<AppReleaseInstall> installs;

  /// When set (e.g. `All release notes`), the footer closes with the notes
  /// link: the label and an arrow, underlined on hover, nothing moving.
  final String? notesLabel;

  /// How many lines of each group show before the rest are counted
  /// (release-card.svelte's `lines` default of 2).
  final int visibleLines;

  @override
  State<AppReleaseCard> createState() => _AppReleaseCardState();
}

class _AppReleaseCardState extends State<AppReleaseCard> {
  String? _manager;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final install = _install;
    final border = BorderSide(color: theme.colors.border, width: theme.style.borderWidth);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          // The card's ring is the foreground at 10%
          // (release-card.svelte ring-1 ring-foreground/10).
          side: BorderSide(
            color: theme.colors.foreground.withValues(alpha: 0.10),
            width: theme.style.borderWidth,
          ),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            // p-6 pb-5: 24dp of air, 20dp onto the body's divider.
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: <Widget>[
                      if (widget.symbol case final symbol? when widget.product != null)
                        Row(
                          children: <Widget>[
                            AppMark(
                              symbol: symbol,
                              squareLabel: widget.symbolLabel ?? widget.product!,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.product!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      Text(
                        widget.version,
                        // text-3xl font-medium tracking-tight, in mono: the
                        // version is a machine value (BRAND.md s8).
                        style: TextStyle(
                          inherit: false,
                          color: theme.colors.foreground,
                          fontFamily: 'JetBrains Mono',
                          fontSize: 30,
                          height: 1.2,
                          letterSpacing: -0.025 * 30,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: <Widget>[
                    if (widget.latestLabel case final latest?) _MaterialEdgeTag(label: latest),
                    Text(
                      widget.date,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            // The body's divider is the card's own hairline (border-t on the
            // outline card), full-bleed like the kit's.
            decoration: BoxDecoration(border: Border(top: border)),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 20,
              children: <Widget>[
                for (final group in widget.groups)
                  _GroupColumn(group: group, visibleLines: widget.visibleLines),
              ],
            ),
          ),
          if (install != null || widget.notesLabel != null)
            Container(
              decoration: BoxDecoration(border: Border(top: border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: <Widget>[
                  if (install != null) ...<Widget>[
                    if (widget.installs.length > 1)
                      AppSegmented<String>(
                        options: <AppSegmentOption<String>>[
                          for (final entry in widget.installs)
                            (value: entry.manager, label: entry.manager, key: null),
                        ],
                        value: install.manager,
                        onChanged: (manager) => setState(() => _manager = manager),
                      ),
                    // The command inset (rounded-lg border py-1 pr-1 pl-3.5):
                    // plain 13dp mono, no prompt, the ghost copy at its end.
                    Container(
                      padding: const EdgeInsetsDirectional.only(
                        start: 14,
                        end: 4,
                        top: 4,
                        bottom: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.transparent,
                        shape: RoundedSuperellipseBorder(
                          side: border,
                          borderRadius: theme.style.borderRadius.md,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              install.command,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                inherit: false,
                                color: theme.colors.foreground,
                                fontFamily: 'JetBrains Mono',
                                fontSize: 13,
                                height: 1.7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppCopyButton(
                            text: install.command,
                            label: 'Copy command',
                            copiedLabel: 'Copied',
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.notesLabel case final notes?)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          notes,
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.foreground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(FLucideIcons.arrowRight, size: 16, color: theme.colors.foreground),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  AppReleaseInstall? get _install => widget.installs.isEmpty
      ? null
      : widget.installs.firstWhere(
          (entry) => entry.manager == _manager,
          orElse: () => widget.installs.first,
        );
}

class _GroupColumn extends StatelessWidget {
  const _GroupColumn({required this.group, required this.visibleLines});

  final AppReleaseGroup group;

  final int visibleLines;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lines = group.lines;
    final shown = lines.take(visibleLines).toList();
    final hidden = lines.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        AppStatusTag(label: '${group.kind.label} ${lines.length}', role: group.kind.role),
        for (final line in shown)
          Text(
            line,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
              height: 1.625,
            ),
          ),
        if (hidden > 0)
          Text(
            'and $hidden more',
            style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
          ),
      ],
    );
  }
}

/// The kit's material tag as drawn here (material-tag.svelte): a 20dp pill
/// whose border is the copper material — the metal runs as a 1.5dp cover
/// around an inner page-colored pill — hugging its label.
///
/// This is the shared `MaterialTag` recipe laid out to hug: the material
/// fills the whole pill, so there it hangs on a tight box; here the
/// non-positioned label pill sizes the stack and the material rides
/// `Positioned.fill` behind it.
class _MaterialEdgeTag extends StatelessWidget {
  const _MaterialEdgeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // The shared MaterialTag's corrected recipe: the pill computes to 23px
    // (1.5 edge + 2 + 16 line + 2 + 1.5), radius half the height.
    const radius = BorderRadius.all(Radius.circular(11.5));
    return SizedBox(
      height: 23,
      child: Stack(
        // The label pill sizes the stack; the material hangs behind it.
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          // The material pill; the inner page-colored pill covers all but
          // the 1.5dp edge, exactly the kit's p-[1.5px] material cover.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: BrandMaterialSurface(recipe: brandMaterialById('copper-sweep')!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(1.5),
            child: DecoratedBox(
              decoration: BoxDecoration(color: theme.colors.background, borderRadius: radius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
