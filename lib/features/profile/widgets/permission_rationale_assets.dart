import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';

/// Resolved copy + leading icon for the permission rationale sheet, keyed off
/// the typed [AppPermission].
///
/// The icon + translation strings live in one exhaustive `switch` so a new
/// permission kind cannot silently fall through to a wrong title / rationale /
/// icon — adding an [AppPermission] is a compile error here until the rationale
/// copy is supplied for it (strict-analysis guardrail).
final class PermissionRationaleCopy {
  const PermissionRationaleCopy._({
    required this.icon,
    required this.title,
    required this.rationale,
  });

  /// Resolves the copy for [permission]. Exhaustive over [AppPermission] — a
  /// new kind is a compile error until a branch is added here.
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

  /// The leading direction-sensitive icon (mirrors under RTL via the host Row).
  final IconData icon;

  /// The localized rationale title (`permission.<kind>.title`).
  final String title;

  /// The localized rationale body explaining why the permission is needed
  /// (`permission.<kind>.rationale`).
  final String rationale;
}
