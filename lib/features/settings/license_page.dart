import 'package:flutter/material.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Thin settings-owned wrapper over Flutter's built-in [LicensePage] (the local
/// OSS/legal attribution registry — backend-free per the feature spec).
///
/// Lives in the settings feature (the bundle's lowest-risk concern lands first;
/// see the spec's Risks). It reads the installed build via
/// [AppBuildInfo] (already a dep) for `applicationVersion` and the app name from
/// the active translation for `applicationName`. `applicationIcon` is omitted:
/// `AppBuildInfo` has no icon field, and the spec calls for omitting it or
/// supplying a bundled asset (no asset is bundled here).
///
/// The page never calls `go_router` directly — it is a leaf reached via the
/// `aboutLicense` route (in-shell under the existing ShellRoute, pushed from a
/// settings "About" tile). The license list itself is Flutter's local registry,
/// so there is **no** port and **no** backend — honest by construction.
///
/// The `package_info_plus` read degrades to a dash on failure so a missing
/// `PackageInfo` (e.g. a test without the binding) never throws into the page.
class AboutLicensePage extends StatefulWidget {
  const AboutLicensePage({this.applicationName, super.key});

  /// Optional override for the application name shown in the license header.
  /// Defaults to the localized app name (`Translations.app.name`) at build time.
  final String? applicationName;

  @override
  State<AboutLicensePage> createState() => _AboutLicensePageState();
}

class _AboutLicensePageState extends State<AboutLicensePage> {
  late final Future<AppBuildInfo> _buildInfo = AppBuildInfo.load();

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(translations.settings.about.license),
        // The license list scrolls; keep the app bar elevated off the scroll
        // content for a clear header on every platform.
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<AppBuildInfo>(
        future: _buildInfo,
        builder: (context, snapshot) {
          // Degrade to a dash when PackageInfo is unavailable (test harness
          // without a mock, or a degenerate empty version) so the page never
          // throws into the list and never shows a fabricated version string
          // (honest — C13).
          final version = _resolveVersion(snapshot.data);
          return LicensePage(
            applicationName: widget.applicationName ?? translations.app.name,
            applicationVersion: version,
            // applicationIcon omitted: AppBuildInfo carries no icon (spec). An
            // empty_legalese keeps the Material widget's default body neutral.
            applicationLegalese: '',
          );
        },
      ),
    );
  }

  /// Resolves the version label honestly: the real version+buildNumber when
  /// present, or `'—'` when [AppBuildInfo] is missing or carries a blank
  /// version (no fabricated string).
  static String _resolveVersion(AppBuildInfo? info) {
    if (info == null) {
      return '—';
    }
    final version = info.version;
    final value = info.displayValue;
    if (version.trim().isEmpty || value.trim().isEmpty || value == '+') {
      return '—';
    }
    return value;
  }
}
