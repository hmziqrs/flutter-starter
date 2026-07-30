import 'package:flutter/material.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Thin wrapper over Flutter's built-in [LicensePage], forwarding the build
/// version and localized app name.
class AboutLicensePage extends StatefulWidget {
  const AboutLicensePage({this.applicationName, super.key});

  /// Defaults to the localized app name when omitted.
  final String? applicationName;

  @override
  State<AboutLicensePage> createState() => _AboutLicensePageState();
}

class _AboutLicensePageState extends State<AboutLicensePage> {
  late final Future<AppBuildInfo> _buildInfo = AppBuildInfo.load();

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    // LicensePage renders its own Scaffold + AppBar; must not be re-wrapped.
    return FutureBuilder<AppBuildInfo>(
      future: _buildInfo,
      builder: (context, snapshot) {
        return LicensePage(
          applicationName: widget.applicationName ?? translations.app.name,
          applicationVersion: _resolveVersion(snapshot.data),
          applicationLegalese: '',
        );
      },
    );
  }

  /// Falls back to `'—'` when [AppBuildInfo] is missing or blank.
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
