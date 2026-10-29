import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
import 'package:starter/shared/widgets/rings/corner_rings.dart';

/// The periodic-table project card (BRAND.md s7 "Project cards (elements)"):
/// an outline card whose corner-rings fingerprint sits FIRST in the stack,
/// in the kind's color, with everything else relative above it.
///
/// Top row: the two-digit [number] in tabular figures (muted) and the
/// optional status tag. Then the [symbol] in [kindColor], the [name], one
/// or two muted [description] sentences, and at the bottom a ring marker
/// plus the [kind]. The rings seed from [seed] — pass the project name, so
/// the same name always draws the same picture.
///
/// Cards keep one color per kind everywhere the kind appears (BRAND.md s4):
/// pass the same [kindColor] for the same kind. Hover is a border tint
/// only; nothing moves (BRAND.md s10).
class ElementCard extends StatefulWidget {
  const ElementCard({
    required this.number,
    required this.symbol,
    required this.name,
    required this.description,
    required this.kind,
    required this.seed,
    required this.kindColor,
    this.statusLabel,
    this.statusRole = AppStatusRole.neutral,
    super.key,
  });

  /// The element's number, rendered as two digits (e.g. 4 -> `04`).
  final int number;

  /// The short symbol drawn large in the kind's color, e.g. `Fx`.
  final String symbol;

  final String name;

  /// One or two plain sentences about the project.
  final String description;

  /// The project kind, e.g. `Library`, `Command-line tool`, `Desktop app`.
  final String kind;

  /// The rings seed — the project's name, per the brand rings recipe.
  final String seed;

  /// The kind's color; the symbol, the ring marker and the rings accent.
  final Color kindColor;

  /// Optional status tag label, e.g. `Shipped`; null draws no tag.
  final String? statusLabel;

  final AppStatusRole statusRole;

  @override
  State<ElementCard> createState() => _ElementCardState();
}

class _ElementCardState extends State<ElementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ringExtent = constraints.maxWidth * 0.7;
          return Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(24),
            decoration: ShapeDecoration(
              color: Colors.transparent,
              shape: RoundedSuperellipseBorder(
                side: BorderSide(
                  color: _hovered
                      ? theme.colors.primary.withValues(alpha: 0.5)
                      : theme.colors.foreground.withValues(alpha: 0.10),
                  width: theme.style.borderWidth,
                ),
                borderRadius: theme.style.borderRadius.lg,
              ),
            ),
            child: Stack(
              children: <Widget>[
                // Corner rings first — the fingerprint sits under everything.
                Positioned(
                  top: 0,
                  right: 0,
                  width: ringExtent,
                  height: ringExtent,
                  child: CornerRings(
                    seed: widget.seed,
                    accentColor: widget.kindColor,
                    size: ringExtent,
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            widget.number.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.2,
                              color: theme.colors.mutedForeground,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (widget.statusLabel != null)
                            AppStatusTag(label: widget.statusLabel!, role: widget.statusRole),
                        ],
                      ),
                      Text(
                        widget.symbol,
                        style: TextStyle(
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.04 * 44,
                          color: widget.kindColor,
                        ),
                      ),
                      Text(
                        widget.name,
                        // The svelte h3 carries tracking-[-0.01em].
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.25,
                          letterSpacing: -0.01 * 18,
                          fontWeight: FontWeight.w500,
                          color: theme.colors.foreground,
                        ),
                      ),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14.4,
                          height: 1.625,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      // mt-auto: the kind row hugs the bottom of a stretched
                      // card and keeps a normal gap at intrinsic height — the
                      // svelte row's mt-auto pt-2, so 8dp more than the
                      // column's 12dp rhythm.
                      if (constraints.hasBoundedHeight)
                        const Spacer()
                      else
                        const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          AppRingMarker(color: widget.kindColor),
                          const SizedBox(width: 8),
                          Text(
                            widget.kind,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
