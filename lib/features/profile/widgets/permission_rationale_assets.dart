import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';

/// Resolved copy + leading icon for the permission rationale sheet. The
/// exhaustive switch below makes a new [AppPermission] a compile error until
/// its copy is supplied.
final class PermissionRationaleCopy {
  const PermissionRationaleCopy._({
    required this.icon,
    required this.title,
    required this.rationale,
  });

  factory PermissionRationaleCopy.forPermission(
    Translations translations,
    AppPermission permission,
  ) {
    return switch (permission) {
      AppPermission.camera => PermissionRationaleCopy._(
        icon: FLucideIcons.camera,
        title: translations.permission.camera.title,
        rationale: translations.permission.camera.rationale,
      ),
      AppPermission.photos => PermissionRationaleCopy._(
        icon: FLucideIcons.image,
        title: translations.permission.photos.title,
        rationale: translations.permission.photos.rationale,
      ),
      AppPermission.location => PermissionRationaleCopy._(
        icon: FLucideIcons.mapPin,
        title: translations.permission.location.title,
        rationale: translations.permission.location.rationale,
      ),
    };
  }

  final IconData icon;
  final String title;
  final String rationale;
}
