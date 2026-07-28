import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';

void main() {
  group('shareServiceProvider', () {
    test('throws until overridden at the composition root', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // riverpod wraps the inner StateError; assert on the surfaced message so
      // the test is stable across riverpod error-wrapper changes.
      expect(
        () => container.read(shareServiceProvider),
        throwsA(
          (Object error) => error.toString().contains('ShareService must be overridden'),
        ),
      );
    });
  });

  group('shareTargetAvailable', () {
    test('true on Android and iOS (native share target)', () {
      // The platform strings come from the same enum the implementation reads,
      // so the case ('iOS' vs 'android') is always correct.
      expect(
        shareTargetAvailable(
          PlatformCapabilities(
            platform: TargetPlatform.android.name,
            isWeb: false,
          ),
        ),
        isTrue,
      );
      expect(
        shareTargetAvailable(
          PlatformCapabilities(
            platform: TargetPlatform.iOS.name,
            isWeb: false,
          ),
        ),
        isTrue,
      );
    });

    test('false on web even when the underlying platform string is android', () {
      expect(
        shareTargetAvailable(
          PlatformCapabilities(
            platform: TargetPlatform.android.name,
            isWeb: true,
            supportsFileSystem: false,
          ),
        ),
        isFalse,
      );
    });

    test('false on desktop where share_plus support is partial', () {
      for (final platform in const <String>['macos', 'windows', 'linux']) {
        expect(
          shareTargetAvailable(
            PlatformCapabilities(platform: platform, isWeb: false),
          ),
          isFalse,
          reason: '$platform should report no native share target',
        );
      }
    });
  });
}
