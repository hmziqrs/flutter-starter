import 'package:package_info_plus/package_info_plus.dart';

final class AppBuildInfo {
  const AppBuildInfo({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;

  String get displayValue => '$version+$buildNumber';

  static Future<AppBuildInfo> load() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppBuildInfo(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}
