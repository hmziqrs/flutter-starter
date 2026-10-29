import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// Which HTTP verb an [AppEndpointCard] speaks, with the token role its
/// chip wears.
enum AppHttpMethod {
  get(AppStatusRole.success),
  post(AppStatusRole.info),
  put(AppStatusRole.warning),
  patch(AppStatusRole.info),
  delete(AppStatusRole.destructive);

  const AppHttpMethod(this.role);

  /// The status role whose soft fill and text color the chip borrows — the
  /// verb is colored only where a status would be.
  final AppStatusRole role;
}

/// An API endpoint surface (the reference kit's card): the verb in its
/// status-colored chip, the path in mono, and the one-sentence summary under
/// them.
///
/// It documents, it does not call — no button, no client; a page that wants
/// to fire a request builds that itself.
class AppEndpointCard extends StatelessWidget {
  const AppEndpointCard({
    required this.method,
    required this.path,
    this.summary,
    super.key,
  });

  final AppHttpMethod method;

  /// The endpoint path, e.g. "/v2/builds/{id}" — a machine value, so it runs
  /// in mono.
  final String path;

  /// What the endpoint does, in muted words.
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    final roleColor = brand.roleColor(method.role);
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
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: AlignmentDirectional.center,
                decoration: ShapeDecoration(
                  color: roleColor?.withValues(alpha: 0.1) ?? theme.colors.secondary,
                  shape: RoundedSuperellipseBorder(borderRadius: theme.style.borderRadius.sm),
                ),
                child: Text(
                  method.name.toUpperCase(),
                  style: theme.typography.body.xs.copyWith(
                    color: roleColor ?? theme.colors.secondaryForeground,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.foreground,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
          if (summary != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              summary!,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}
