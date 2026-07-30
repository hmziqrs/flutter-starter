import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/security/passcode_page.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

/// Builds the passcode + auto-lock gallery cases: the entry surface in its
/// three runtime states (idle, error, locked-out) and the setup surface with a
/// confirm-mismatch. The controller is pinned via a gallery-only override
/// backed by an in-memory [SecureStore], so a stray submit never reaches the
/// keychain.
List<GalleryCase> buildPinAutolockGalleryCases() {
  return [
    TypedGalleryCase<_PasscodeFixture>(
      id: 'passcode.entry.idle',
      screenId: 'passcodeEntry',
      screenLabelBuilder: (translations) => translations.devGallery.screenPasscodeEntry,
      caseLabelBuilder: (translations) => translations.devGallery.casePasscodeIdle,
      stateFactory: (_) => const _PasscodeFixture(),
      pageFactory: (context, state) => _PasscodePreview(state: state),
    ),
    TypedGalleryCase<_PasscodeFixture>(
      id: 'passcode.entry.error',
      screenId: 'passcodeEntry',
      screenLabelBuilder: (translations) => translations.devGallery.screenPasscodeEntry,
      caseLabelBuilder: (translations) => translations.devGallery.casePasscodeError,
      stateFactory: (_) => const _PasscodeFixture(),
      pageFactory: (context, state) => _PasscodePreview(state: state),
    ),
    TypedGalleryCase<_PasscodeFixture>(
      id: 'passcode.entry.lockedOut',
      screenId: 'passcodeEntry',
      screenLabelBuilder: (translations) => translations.devGallery.screenPasscodeEntry,
      caseLabelBuilder: (translations) => translations.devGallery.casePasscodeLockedOut,
      stateFactory: (_) => const _PasscodeFixture(),
      pageFactory: (context, state) =>
          const _PasscodePreview(state: _PasscodeFixture(), lockedOut: true),
    ),
    TypedGalleryCase<_PasscodeFixture>(
      id: 'passcode.setup.mismatch',
      screenId: 'passcodeSetup',
      screenLabelBuilder: (translations) => translations.devGallery.screenPasscodeSetup,
      caseLabelBuilder: (translations) => translations.devGallery.casePasscodeSetupMismatch,
      stateFactory: (_) => const _PasscodeFixture(),
      pageFactory: (context, state) => const _PasscodePreview(
        state: _PasscodeFixture(),
        setup: true,
      ),
    ),
  ];
}

@immutable
final class _PasscodeFixture {
  const _PasscodeFixture();
}

/// Pins [PasscodePage] inside a nested [ProviderScope] so the preview never
/// reaches the OS keychain and never navigates.
class _PasscodePreview extends StatelessWidget {
  const _PasscodePreview({required this.state, this.lockedOut = false, this.setup = false});

  final _PasscodeFixture state;
  final bool lockedOut;
  final bool setup;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        secureStoreProvider.overrideWithValue(_EmptySecureStore()),
        passcodeControllerProvider.overrideWith(
          () => _PinnedPasscodeController(lockedOut: lockedOut),
        ),
      ],
      child: PasscodePage(
        mode: setup ? PasscodePageMode.setup : PasscodePageMode.entry,
        onUnlocked: () {},
        onSetupComplete: () {},
        onDisable: () {},
      ),
    );
  }
}

/// Gallery-only `PasscodeController` that returns a fixed state and never
/// reads the keychain.
class _PinnedPasscodeController extends PasscodeController {
  _PinnedPasscodeController({required this.lockedOut});

  final bool lockedOut;

  @override
  PasscodeState build() {
    if (lockedOut) {
      return PasscodeState(
        enabled: true,
        isSet: true,
        attemptsRemaining: 0,
        lockedUntil: DateTime.now().add(const Duration(minutes: 1)),
      );
    }
    return const PasscodeState(
      enabled: true,
      isSet: true,
      attemptsRemaining: freeAttemptsBeforeLockout,
      lockedUntil: null,
    );
  }

  @override
  Future<PasscodeVerifyResult> verify(String pin) async => PasscodeVerifyResult.incorrect;
}

/// In-memory [SecureStore] whose reads always return nothing.
final class _EmptySecureStore implements SecureStore {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}
