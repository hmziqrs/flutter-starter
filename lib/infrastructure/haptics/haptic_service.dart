import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The canonical tactile-feedback kinds the starter triggers.
///
/// A typed, closed enum so the port surface never leaks a raw string and every
/// call site handles the full set via an exhaustive `switch` (no `default`).
/// Maps one-to-one onto the cross-platform `HapticFeedback` surface from
/// `flutter/services` (see `DeviceHapticService`). iOS Taptic Engine and Android
/// vibrator differ in amplitude/quality — the enum promises a *category*, not
/// parity, and intentionally does not expose the raw `HapticFeedback.vibrate`
/// "buzz" (use an impact kind instead).
///
/// The small canonical trigger set the starter reserves for these kinds:
/// toggles / discrete selection -> `selection`; pull-to-refresh / scrubbing ->
/// `impactLight`; expansion / medium commits -> `impactMedium`; destructive
/// confirms / heavy commits -> `impactHeavy`; success notifications ->
/// `notificationSuccess`; warning notifications -> `notificationWarning`; error
/// notifications -> `notificationError`. Resist ad-hoc sprinkling beyond this.
enum HapticKind {
  selection,
  impactLight,
  impactMedium,
  impactHeavy,
  notificationSuccess,
  notificationWarning,
  notificationError,
}

/// Tactile-feedback port. Mirrors the `SettingsStore` port shape (single-purpose,
/// `Future`-returning, typed exception, `try/on Object` degradation inside the
/// adapters, no `clearAll`-style bulk call). Backend-free per spec: the
/// production adapter (`DeviceHapticService`) talks to the OS directly through
/// `flutter/services`; the deterministic `NoopHapticService` records calls and
/// fires nothing, used for goldens/integration hermeticity.
///
/// Haptics are fire-and-forget: a platform failure surfaces as
/// `HapticServiceException` for port-discipline (consistent with
/// `SettingsStoreException`) and is swallowed by call sites via
/// `Future.ignore()` — a failed buzz never gates or fails a user action.
// A single dispatch method is the intended shape for this port (an exhaustive
// `switch` over `HapticKind` lives in the device adapter). The one-member
// abstract lint is a false positive for a multi-implementation port.
// ignore: one_member_abstracts
abstract interface class HapticService {
  /// Fires the platform haptic for [kind]. Never blocks a caller that treats it
  /// as fire-and-forget; a platform failure throws `HapticServiceException`.
  Future<void> trigger(HapticKind kind);
}

/// Thrown by `HapticService` adapters only for platform-call failures (a missing
/// channel binding, an unsupported platform, etc.). Call sites treat haptics as
/// fire-and-forget and swallow this; it is surfaced for port-shape consistency
/// with `SettingsStoreException` and so a regression in the kind ->
/// `HapticFeedback` mapping is observable in a unit test.
final class HapticServiceException implements Exception {
  const HapticServiceException({required this.operation, required this.kind});

  final String operation;
  final HapticKind kind;

  @override
  String toString() => 'HapticServiceException: $operation failed for ${kind.name}';
}

/// Handwritten Riverpod handle for the `HapticService` port.
///
/// Mirrors `settingsRepositoryProvider` / `biometricAuthenticatorProvider`: it
/// throws a [StateError] until the composition root overrides it with a concrete
/// adapter. The composition root selects the real `DeviceHapticService` as the
/// production default (the local device IS the backend — no credentials, no
/// faking) and overrides it with `NoopHapticService` in tests / goldens for
/// hermeticity. The settings opt-out (`hapticsEnabled`) and the reduce-motion
/// guard (`MediaQuery.disableAnimationsOf`) are enforced at each call site, not
/// here — see the haptics gallery case for the canonical gating contract.
final hapticServiceProvider = Provider<HapticService>(
  (ref) => throw StateError('HapticService must be overridden at the composition root.'),
);
