import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';

/// A changelog entry (the release kit's card): the version in mono, the date
/// and an optional channel tag in the header, then the changes as ring
/// markers — hollow until a change means something worth filling.
class AppReleaseCard extends StatelessWidget {
  const AppReleaseCard({
    required this.version,
    required this.date,
    required this.changes,
    this.channelLabel,
    this.channelRole = AppStatusRole.neutral,
    super.key,
  });

  /// The release version, e.g. "2026.10.2" — a machine value, so it runs in
  /// mono.
  final String version;

  /// The release date, in the caller's words.
  final String date;

  /// The changes, one line each.
  final List<String> changes;

  /// The channel tag's label, e.g. "Staged"; absent, no tag shows.
  final String? channelLabel;

  /// The channel tag's role.
  final AppStatusRole channelRole;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
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
              Text(
                version,
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
                ),
              ),
              if (channelLabel != null) ...<Widget>[
                const SizedBox(width: 8),
                AppStatusTag(label: channelLabel!, role: channelRole),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < changes.length; index++)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(padding: EdgeInsets.only(top: 5), child: AppRingMarker()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      changes[index],
                      style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
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
