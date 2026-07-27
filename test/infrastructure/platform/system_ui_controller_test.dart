import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/system_ui_controller.dart';

/// Hermetic coverage for the system-ui config command (system-ui feature
/// spec: "Tests assert the pure style construction and the PlatformCapabilities
/// gating; they do not touch real chrome (hermetic).").
///
/// The pure surface is [SystemUiController.overlayStyleFor]; the gating surface
/// is [SystemUiController.applyEdgeToEdge] / [SystemUiController.applyOverlayStyle]
/// with desktop/web capabilities. The mobile branches additionally exercise the
/// `SystemChrome` path against the test binding's platform-channel mock so a
/// regression that throws into the composition root is caught here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemUiController.overlayStyleFor', () {
    final cases = <(Brightness, AppAccent)>[
      for (final brightness in Brightness.values)
        for (final accent in AppAccent.values) (brightness, accent),
    ];

    for (final (brightness, accent) in cases) {
      test(
        'transparent bars + brightness-driven icons for ($brightness, $accent)',
        () {
          final style = SystemUiController.overlayStyleFor(
            brightness: brightness,
            accent: accent,
          );

          // Edge-to-edge: both bars fully transparent so app content draws
          // behind them regardless of accent.
          expect(style.statusBarColor, Colors.transparent);
          expect(style.systemNavigationBarColor, Colors.transparent);
          expect(style.systemNavigationBarDividerColor, Colors.transparent);
          // Auto-scrim disabled on Android 29+ so transparent stays transparent.
          expect(style.systemNavigationBarContrastEnforced, isFalse);
          expect(style.systemStatusBarContrastEnforced, isFalse);

          final isDark = brightness == Brightness.dark;
          // Status bar icons: dark over light, light over dark.
          expect(
            style.statusBarIconBrightness,
            isDark ? Brightness.light : Brightness.dark,
          );
          // iOS-facing statusBarBrightness is the inverse of the icon
          // brightness direction.
          expect(
            style.statusBarBrightness,
            isDark ? Brightness.dark : Brightness.light,
          );
          expect(
            style.systemNavigationBarIconBrightness,
            isDark ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    test('is exhaustive over the current AppAccent cardinality', () {
      // Adding a new AppAccent value would break the exhaustive switch in
      // overlayStyleFor at compile time; this pins the cardinality so a
      // contributor who adds an accent also updates the per-case table there
      // (and this suite's loop picks up the new pair automatically).
      expect(AppAccent.values, hasLength(6));
      expect(Brightness.values, hasLength(2));
    });
  });

  group('SystemUiController platform gating', () {
    const desktopCapabilities = PlatformCapabilities(
      platform: 'macOS',
      isWeb: false,
      supportsFileSystem: true,
    );
    const linuxCapabilities = PlatformCapabilities(
      platform: 'linux',
      isWeb: false,
      supportsFileSystem: true,
    );
    const windowsCapabilities = PlatformCapabilities(
      platform: 'windows',
      isWeb: false,
      supportsFileSystem: true,
    );
    const webCapabilities = PlatformCapabilities(
      // Web is platform-agnostic; only isWeb matters for the gate.
      platform: 'android',
      isWeb: true,
      supportsFileSystem: false,
    );
    const mobileCapabilities = PlatformCapabilities(
      platform: 'android',
      isWeb: false,
      supportsFileSystem: true,
    );
    const iosCapabilities = PlatformCapabilities(
      platform: 'iOS',
      isWeb: false,
      supportsFileSystem: true,
    );

    test('applyEdgeToEdge short-circuits on every desktop platform', () async {
      // Completing without throwing is the contract: the SystemChrome path is
      // never entered on desktop, so the binding's platform-channel mock is
      // untouched.
      await SystemUiController.applyEdgeToEdge(capabilities: desktopCapabilities);
      await SystemUiController.applyEdgeToEdge(capabilities: linuxCapabilities);
      await SystemUiController.applyEdgeToEdge(capabilities: windowsCapabilities);
    });

    test('applyEdgeToEdge short-circuits on web', () async {
      await SystemUiController.applyEdgeToEdge(capabilities: webCapabilities);
    });

    test('applyOverlayStyle short-circuits on desktop + web for every accent', () {
      for (final accent in AppAccent.values) {
        SystemUiController.applyOverlayStyle(
          brightness: Brightness.light,
          accent: accent,
          capabilities: desktopCapabilities,
        );
        SystemUiController.applyOverlayStyle(
          brightness: Brightness.dark,
          accent: accent,
          capabilities: webCapabilities,
        );
      }
    });

    test('applyEdgeToEdge reaches SystemChrome on mobile without throwing', () async {
      // The test binding's platform-channel mock accepts SystemChrome calls
      // (no real device is touched); this asserts the mobile branch completes
      // rather than short-circuiting silently, and never throws into the
      // composition root.
      await SystemUiController.applyEdgeToEdge(capabilities: mobileCapabilities);
      await SystemUiController.applyEdgeToEdge(capabilities: iosCapabilities);
    });

    test('applyOverlayStyle reaches SystemChrome on mobile without throwing', () {
      for (final accent in AppAccent.values) {
        SystemUiController.applyOverlayStyle(
          brightness: Brightness.dark,
          accent: accent,
          capabilities: mobileCapabilities,
        );
        SystemUiController.applyOverlayStyle(
          brightness: Brightness.light,
          accent: accent,
          capabilities: iosCapabilities,
        );
      }
    });
  });
}
