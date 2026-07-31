import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/system_ui_controller.dart';

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

          expect(style.statusBarColor, Colors.transparent);
          expect(style.systemNavigationBarColor, Colors.transparent);
          expect(style.systemNavigationBarDividerColor, Colors.transparent);
          expect(style.systemNavigationBarContrastEnforced, isFalse);
          expect(style.systemStatusBarContrastEnforced, isFalse);

          final isDark = brightness == Brightness.dark;
          expect(
            style.statusBarIconBrightness,
            isDark ? Brightness.light : Brightness.dark,
          );
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
      expect(AppAccent.values, hasLength(6));
      expect(Brightness.values, hasLength(2));
    });
  });

  group('SystemUiController platform gating', () {
    const desktopCapabilities = PlatformCapabilities(
      platform: 'macOS',
      isWeb: false,
    );
    const linuxCapabilities = PlatformCapabilities(
      platform: 'linux',
      isWeb: false,
    );
    const windowsCapabilities = PlatformCapabilities(
      platform: 'windows',
      isWeb: false,
    );
    const webCapabilities = PlatformCapabilities(
      platform: 'android',
      isWeb: true,
      supportsFileSystem: false,
    );
    const mobileCapabilities = PlatformCapabilities(
      platform: 'android',
      isWeb: false,
    );
    const iosCapabilities = PlatformCapabilities(
      platform: 'iOS',
      isWeb: false,
    );

    test('applyEdgeToEdge short-circuits on every desktop platform', () async {
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
