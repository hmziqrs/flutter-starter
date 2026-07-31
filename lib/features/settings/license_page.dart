import 'package:flutter/material.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

class AboutLicensePage extends StatefulWidget {
  const AboutLicensePage({this.applicationName, super.key});

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
