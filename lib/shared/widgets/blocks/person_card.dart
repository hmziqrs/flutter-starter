import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A person surface (the people kit's card): an initial-avatar ring, the
/// name at w500, the role in muted words, and an optional one-sentence bio.
///
/// The avatar is drawn, never photographed: initials in a hollow ring, the
/// brand's answer to a headshot it does not have.
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

  /// One sentence about the person, under the divider.
  final String? bio;

  /// Short link labels, shown as a muted row at the card's foot.
  final List<String> links;

  /// A widget pinned to the card's trailing edge, e.g. a status tag.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: AlignmentDirectional.center,
                decoration: ShapeDecoration(
                  color: Colors.transparent,
                  shape: RoundedSuperellipseBorder(
                    side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  initials,
                  style: theme.typography.body.md.copyWith(
                    color: theme.colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.typography.body.lg.copyWith(
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
              ),
            ],
          ),
          if (bio != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              bio!,
              style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
            ),
          ],
          if (links.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: <Widget>[
                for (final link in links)
                  Text(
                    link,
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
