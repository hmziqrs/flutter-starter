import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

/// One-shot system-chrome configuration: edge-to-edge + reactive overlay style.
///
/// Backend-free presentation/config command (no port, no provider — the default
/// and only impl is the real device `SystemChrome`). Per the system-ui spec,
/// the value object is the [SystemUiOverlayStyle] derived from [Brightness] +
/// [AppAccent]; both side effects run from the composition root only:
///
///   1. [applyEdgeToEdge] — once, in `createApplication` after binding init
///      (see `lib/bootstrap.dart`).
///   2. [applyOverlayStyle] — in `_AppView.build`, tracking theme + accent
///      (see `lib/app/app.dart`).
///
/// Both are platform-gated via [PlatformCapabilities]: desktop and web
/// short-circuit to no-ops so a macOS/Linux/Windows/web runner never touches a
/// mobile-only API. Mobile calls go through `SystemChrome` directly — no widget
/// calls a plugin directly (composition root only, per the architecture
/// guardrail). Branching happens on [PlatformCapabilities], never on scattered
/// `Platform.is*` checks (system-ui risk note).
///
/// The default and only impl is real and local: there is intentionally **no**
/// Noop/InMemory variant and **no** `tools/test_server/` route — system chrome
/// is backend-free config, not a side-effecting service (C2 explicitly exempts
/// this feature: no port required).
abstract final class SystemUiController {
  /// Desktop platform names (per `defaultTargetPlatform.name`) that have no
  /// mobile-style status / navigation bars. Web is gated separately via
  /// [PlatformCapabilities.isWeb].
  static const Set<String> _desktopPlatforms = {'macOS', 'linux', 'windows'};

  /// Opts into Android/iOS edge-to-edge with transparent system bars.
  ///
  /// `SystemUiMode.edgeToEdge` makes both the status and navigation bars
  /// transparent so app content draws behind them; the bar foreground (icons)
  /// is then flipped per-theme by [applyOverlayStyle]. Android 15 (API 35)
  /// **enforces** edge-to-edge for apps targeting a modern `targetSdk`, so this
  /// MUST run before the first frame on every mobile launch — skipping it ships
  /// a visually broken layout on current devices.
  ///
  /// Desktop and web short-circuit (no system bars to configure) — they never
  /// invoke `SystemChrome` so the binding's platform-channel mock is untouched
  /// on those runners (the macOS golden matrix is unaffected for this reason).
  ///
  /// The [capabilities] parameter is injected (rather than read from
  /// [PlatformCapabilities.current] inside) so the composition root remains the
  /// single place that resolves the live platform, and tests can drive both
  /// branches hermetically.
  static Future<void> applyEdgeToEdge({
    required PlatformCapabilities capabilities,
  }) async {
    if (_isDesktopOrWeb(capabilities)) {
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Publishes the [SystemUiOverlayStyle] for the current [brightness] +
  /// [accent]. Idempotent: invoked from `_AppView.build` on every theme/accent
  /// change so the system bars track the active ForUI theme. Desktop and web
  /// short-circuit (no system bars to style).
  ///
  /// The style is resolved via [overlayStyleFor], the pure value constructor
  /// that is the hermetic test surface for this feature. Synchronous by design
  /// — `SystemChrome.setSystemUIOverlayStyle` is itself synchronous (it posts a
  /// platform message and returns immediately), so a `build` method can call
  /// this directly without an `await` or `unawaited` wrapper.
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
  /// Pure value constructor — the hermetic test surface for this feature
  /// (tests assert every `(brightness, accent)` pair, never the real chrome).
  /// Bars are transparent (true edge-to-edge); only the foreground (status and
  /// navigation bar icons) is tinted per [brightness]:
  ///
  ///   - [Brightness.light] theme → dark icons over light app content.
  ///   - [Brightness.dark] theme → light icons over dark app content.
  ///
  /// [accent] is part of the signature today for symmetry with the theme
  /// factory and is the integration hook for a future brand-tinted status-bar
  /// variant; the conservative edge-to-edge default keeps bars transparent
  /// regardless of accent so the brand color never fights the foreground. The
  /// exhaustive switch over `(brightness, accent)` means adding a new
  /// [AppAccent] value is a compile error here (strict-analysis guardrail 7),
  /// and a future per-accent tint can diverge inside the switch without
  /// touching any call site.
  ///
  /// `systemNavigationBarContrastEnforced` / `systemStatusBarContrastEnforced`
  /// are disabled so a transparent navigation bar does not pick up an
  /// auto-scrim (Android 29+) that would dim the content behind it — mandatory
  /// for the edge-to-edge look.
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
          // iOS-facing statusBarBrightness describes the bar background
          // brightness for the platform's contrast decision — the inverse
          // direction from the Android icon brightness above.
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
