import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A person (person-card.svelte, card variant): the initial-avatar ring, then
/// the name and role as a tight pair, the one-sentence bio, and the links at
/// the card's foot — all in one top-start column with 16dp between the
/// blocks.
///
/// The avatar is drawn, never photographed: initials in a hollow ring (the
/// brand's answer to a headshot it does not have), 40dp with the foreground
/// at 15% for its ring and the initials in 14dp muted w500.
class AppPersonCard extends StatelessWidget {
  const AppPersonCard({
    required this.name,
    this.role,
    this.bio,
    this.links = const <String>[],
    this.trailing,
    super.key,
  });

  /// The person's name; the avatar takes its initials.
  final String name;

  /// What the person does, in muted words under the name.
  final String? role;

  /// One sentence about the person, under the name pair.
  final String? bio;

  /// Short link labels, shown as a muted row at the card's foot (the kit
  /// draws icon buttons there; the labels stand in for the icons).
  final List<String> links;

  /// A widget pinned beside the name, e.g. a status tag.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // A bounded height (a stretched grid cell) pins the links to the foot,
    // like the svelte card's mt-auto socials wrapper.
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = context.theme;
        final initials = name
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join();
        return Container(
          // The card's ring is the foreground at 10%, not the border color
          // (person-card.svelte: ring-1 ring-foreground/10), with 24dp of air
          // (p-6) and 16dp between the blocks (gap-4).
          padding: const EdgeInsets.all(24),
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                color: theme.colors.foreground.withValues(alpha: 0.10),
                width: theme.style.borderWidth,
              ),
              borderRadius: theme.style.borderRadius.lg,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: <Widget>[
              Container(
                // The avatar runs 40dp (the kit's Avatar lg), its ring the
                // foreground at 15% (Avatar.Fallback ring-foreground/15), the
                // initials 14dp muted w500 (the fallback's text-sm
                // text-muted-foreground + font-medium).
                width: 40,
                height: 40,
                alignment: AlignmentDirectional.center,
                decoration: ShapeDecoration(
                  color: Colors.transparent,
                  shape: RoundedSuperellipseBorder(
                    side: BorderSide(
                      color: theme.colors.foreground.withValues(alpha: 0.15),
                      width: theme.style.borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  initials,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // The name pair: name at 16dp w500 (the kit's h3 font-medium at
              // body size), role 14dp muted, 2dp apart (flex-col gap-0.5).
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.md.copyWith(
                            color: theme.colors.foreground,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!],
                    ],
                  ),
                  if (role != null)
                    Text(
                      role!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                ],
              ),
              if (bio != null)
                // The bio reads muted at relaxed leading (text-sm
                // leading-relaxed).
                Text(
                  bio!,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.625,
                  ),
                ),
              if (links.isNotEmpty)
                // One child either way, so a stretched cell keeps the same
                // gaps it was measured with; a spacer here would add a gap.
                _foot(
                  pinned: constraints.hasBoundedHeight,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: <Widget>[
                      for (final link in links)
                        Text(
                          link,
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _foot({required bool pinned, required Widget child}) {
    if (!pinned) return child;
    return Expanded(
      child: Align(alignment: AlignmentDirectional.bottomStart, child: child),
    );
  }
}
