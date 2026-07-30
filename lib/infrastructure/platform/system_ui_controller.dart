import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

/// One-shot system-chrome configuration: edge-to-edge + reactive overlay style.
///
/// Backend-free; the only impl is the real device `SystemChrome`, called only
/// from the composition root ([applyEdgeToEdge] once in `lib/bootstrap.dart`,
/// [applyOverlayStyle] in `_AppView.build`). Desktop and web short-circuit to
/// no-ops via [PlatformCapabilities] (never `Platform.is*` checks directly).
abstract final class SystemUiController {
  static const Set<String> _desktopPlatforms = {'macOS', 'linux', 'windows'};

  /// Opts into Android/iOS edge-to-edge with transparent system bars.
  ///
  /// Must run before the first frame on mobile: Android 15 (API 35) enforces
  /// edge-to-edge for modern `targetSdk`, so skipping this ships a broken
  /// layout. Desktop/web short-circuit — they never touch `SystemChrome`.
  static Future<void> applyEdgeToEdge({
    required PlatformCapabilities capabilities,
  }) async {
    if (_isDesktopOrWeb(capabilities)) {
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Publishes the [SystemUiOverlayStyle] for the current [brightness] +
  /// [accent]. Called from `_AppView.build` on every theme/accent change.
  /// Desktop and web short-circuit. Synchronous — `setSystemUIOverlayStyle`
  /// posts a platform message and returns immediately.
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

  /// Derives the [SystemUiOverlayStyle] for the given [brightness] + [accent].
  ///
  /// Bars stay transparent (true edge-to-edge); only icon brightness flips
  /// per-theme. [accent] is part of the signature for symmetry with the theme
  /// factory / future per-accent tinting, though the current mapping ignores
  /// it. Contrast-enforced flags are disabled so a transparent navigation bar
  /// doesn't pick up an auto-scrim on Android 29+.
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
          // statusBarBrightness is the iOS bar background brightness (inverse
          // of the Android icon brightness above).
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
