import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/security/biometric_lock_page.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';

/// Builds the biometric lock gallery cases: the [BiometricLockLocked] prompt
/// and the [BiometricLockUnavailable] fallback surface.
///
/// Both fixtures are deterministic — no platform biometric prompt, no plugin
/// call, no navigation. The page is pinned to the preview state via a
/// gallery-only controller override, and the underlying authenticator is the
/// honest [NoopBiometricAuthenticator] so an accidental tap degrades to the
/// failure alert rather than triggering the OS prompt (C2 / C13: the gallery
/// never fakes a successful unlock).
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

/// Pins [BiometricLockPage] to a fixed lock state inside a nested
/// [ProviderScope]. The PreviewFrame already provides a ProviderScope
/// (interactionPolicy); this nests one that overrides the controller and the
/// authenticator so the preview never reaches the platform plugin.
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
        // Gallery callbacks are deterministic no-ops: the preview never
        // navigates and never fakes an unlock.
        onUnlocked: () {},
        onUseFallback: () {},
      ),
    );
  }
}

/// Gallery-only [BiometricUnlockController] that returns a fixed state and
/// never reads the OS availability (mirrors the gallery-only
/// `_FixedConnectivityService` pattern in the connectivity gallery cases).
class _PinnedBiometricUnlockController extends BiometricUnlockController {
  _PinnedBiometricUnlockController(this.pinnedState);

  final BiometricLockState pinnedState;

  @override
  BiometricLockState build() => pinnedState;
}
