import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/dev_gallery/gallery_registry.dart';

void main() {
  test('registry assembles every production and system case with unique IDs', () {
    final cases = buildGalleryRegistry(config: _developmentConfig);
    final ids = cases.map((galleryCase) => galleryCase.id).toList();

    expect(cases, hasLength(156));
    expect(ids.toSet(), hasLength(ids.length));
    expect(
      ids,
      containsAll(<String>[
        'auth.login.focused',
        'auth.otp.registration.pastedComplete',
        'auth.otp.passwordReset.pastedComplete',
        'profile.update.discardPrompt',
        'system.startupFailure',
        'overlays.keyboardInset',
        'connectivity.offline',
        'forceUpdate.hard',
        'softUpdate.card',
        'busy.overlay',
        'splash.loading',
        'stateViews.empty',
        'formScaffold.enabled',
        'announcements.critical',
        'session.loggedOut',
        'session.loggedIn',
        'analytics.optIn.on',
        'analytics.optIn.off',
        'biometric.locked',
        'biometric.unavailable',
        'pullRefresh.list',
        'pullRefresh.grid',
        'skeleton.staticList',
        'skeleton.shimmerList',
        'haptics.kinds',
        'accessibility.comfortable',
        'accessibility.large',
        'accessibility.dyslexia',
        'searchPagination.field',
        'searchPagination.paged',
        'searchPagination.pagedNoBackend',
        'passcode.entry.idle',
        'passcode.entry.error',
        'passcode.entry.lockedOut',
        'passcode.setup.mismatch',
        'feedback.drafting',
        'feedback.submitting',
        'feedback.failed',
        'feedback.success',
      ]),
    );
    expect(
      cases.every(
        (galleryCase) => galleryCase.id.trim().isNotEmpty && galleryCase.screenId.trim().isNotEmpty,
      ),
      isTrue,
    );
  });

  test('registry result cannot be mutated', () {
    final cases = buildGalleryRegistry(config: _developmentConfig);
    expect(cases.removeLast, throwsUnsupportedError);
  });
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);
