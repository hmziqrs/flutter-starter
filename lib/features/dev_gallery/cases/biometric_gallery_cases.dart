import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/security/biometric_lock_page.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';

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

class _PinnedBiometricUnlockController extends BiometricUnlockController {
  _PinnedBiometricUnlockController(this.pinnedState);

  final BiometricLockState pinnedState;

  @override
  BiometricLockState build() => pinnedState;
}
