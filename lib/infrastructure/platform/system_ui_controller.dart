import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

abstract final class SystemUiController {
  static const Set<String> _desktopPlatforms = {'macOS', 'linux', 'windows'};

  static Future<void> applyEdgeToEdge({
    required PlatformCapabilities capabilities,
  }) async {
    if (_isDesktopOrWeb(capabilities)) {
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  static void applyOverlayStyle({
    required Brightness brightness,
    required AppAccent accent,
    required PlatformCapabilities capabilities,
  }) {
    if (_isDesktopOrWeb(capabilities)) {
      return;
    }
    SystemChrome.setSystemUIOverlayStyle(
      overlayStyleFor(brightness: brightness, accent: accent),
    );
  }

  static SystemUiOverlayStyle overlayStyleFor({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    return switch ((brightness, accent)) {
      (
        Brightness.light,
        AppAccent.neutral ||
            AppAccent.green ||
            AppAccent.blue ||
            AppAccent.amber ||
            AppAccent.rose ||
            AppAccent.violet,
      ) =>
        _style(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          navigationBarIconBrightness: Brightness.dark,
        ),
      (
        Brightness.dark,
        AppAccent.neutral ||
            AppAccent.green ||
            AppAccent.blue ||
            AppAccent.amber ||
            AppAccent.rose ||
            AppAccent.violet,
      ) =>
        _style(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          navigationBarIconBrightness: Brightness.light,
        ),
    };
  }

  static SystemUiOverlayStyle _style({
    required Brightness statusBarIconBrightness,
    required Brightness statusBarBrightness,
    required Brightness navigationBarIconBrightness,
  }) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: navigationBarIconBrightness,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  static bool _isDesktopOrWeb(PlatformCapabilities capabilities) {
    if (capabilities.isWeb) {
      return true;
    }
    return _desktopPlatforms.contains(capabilities.platform);
  }
}
