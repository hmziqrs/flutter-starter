import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/security/biometric_lock_page.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';

/// Builds the biometric lock gallery cases: the [BiometricLockLocked] prompt
/// and the [BiometricLockUnavailable] fallback surface. Both pin the page via
/// a gallery-only controller override with [NoopBiometricAuthenticator], so
/// an accidental tap degrades to the failure alert instead of the OS prompt.
List<GalleryCase> buildBiometricGalleryCases() {
  return [
    TypedGalleryCase<BiometricLockState>(
      id: 'biometric.locked',
      screenId: 'biometricLock',
      screenLabelBuilder: (translations) => translations.devGallery.screenBiometricLock,
      caseLabelBuilder: (translations) => translations.devGallery.caseLocked,
      stateFactory: (_) => const BiometricLockLocked(),
      pageFactory: (context, state) => _BiometricPreview(state: state),
    ),
    TypedGalleryCase<BiometricLockState>(
      id: 'biometric.unavailable',
      screenId: 'biometricLock',
      screenLabelBuilder: (translations) => translations.devGallery.screenBiometricLock,
      caseLabelBuilder: (translations) => translations.devGallery.caseUnavailable,
      stateFactory: (_) => const BiometricLockUnavailable(),
      pageFactory: (context, state) => _BiometricPreview(state: state),
    ),
  ];
}

/// Pins [BiometricLockPage] to a fixed lock state, overriding the controller
/// and authenticator so the preview never reaches the platform plugin.
class _BiometricPreview extends StatelessWidget {
  const _BiometricPreview({required this.state});

  final BiometricLockState state;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        biometricAuthenticatorProvider.overrideWithValue(const NoopBiometricAuthenticator()),
        biometricUnlockControllerProvider.overrideWith(
          () => _PinnedBiometricUnlockController(state),
        ),
      ],
      child: BiometricLockPage(
        onUnlocked: () {},
        onUseFallback: () {},
      ),
    );
  }
}

/// Gallery-only [BiometricUnlockController] that returns a fixed state and
/// never reads the OS availability.
class _PinnedBiometricUnlockController extends BiometricUnlockController {
  _PinnedBiometricUnlockController(this.pinnedState);

  final BiometricLockState pinnedState;

  @override
  BiometricLockState build() => pinnedState;
}
