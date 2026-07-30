import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The canonical tactile-feedback kinds the starter triggers, mapping
/// one-to-one onto the cross-platform `HapticFeedback` surface from
/// `flutter/services`. iOS Taptic Engine and Android vibrator differ in
/// amplitude/quality — the enum promises a category, not parity, and
/// intentionally excludes the raw `HapticFeedback.vibrate` buzz.
///
/// Canonical usage: toggles / discrete selection -> `selection`;
/// pull-to-refresh / scrubbing -> `impactLight`; expansion / medium commits ->
/// `impactMedium`; destructive confirms / heavy commits -> `impactHeavy`;
/// success/warning/error notifications -> the matching `notification*` kind.
enum HapticKind {
  selection,
  impactLight,
  impactMedium,
  impactHeavy,
  notificationSuccess,
  notificationWarning,
  notificationError,
}

/// Tactile-feedback port. Production adapter (`DeviceHapticService`) talks to
/// the OS via `flutter/services`; `NoopHapticService` records calls and fires
/// nothing, for goldens/integration hermeticity.
///
/// Haptics are fire-and-forget: call sites swallow `HapticServiceException`
/// via `Future.ignore()` — a failed buzz never gates a user action.
// One-member abstract lint is a false positive for a multi-implementation port.
// ignore: one_member_abstracts
abstract interface class HapticService {
  /// Fires the platform haptic for [kind]. A platform failure throws
  /// `HapticServiceException`, swallowed by fire-and-forget callers.
  Future<void> trigger(HapticKind kind);
}

/// Thrown by `HapticService` adapters only for platform-call failures.
final class HapticServiceException implements Exception {
  const HapticServiceException({required this.operation, required this.kind});

  final String operation;
  final HapticKind kind;

  @override
  String toString() => 'HapticServiceException: $operation failed for ${kind.name}';
}

/// Throws a [StateError] until the composition root overrides it with a
/// concrete adapter (`DeviceHapticService` in production, `NoopHapticService`
/// in tests/goldens). The settings opt-out and reduce-motion guard are
/// enforced at each call site, not here.
final hapticServiceProvider = Provider<HapticService>(
  (ref) => throw StateError('HapticService must be overridden at the composition root.'),
);
