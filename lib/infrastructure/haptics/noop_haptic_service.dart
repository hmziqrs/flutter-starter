import 'package:starter/infrastructure/haptics/haptic_service.dart';

/// Deterministic, hermeticity-only `HapticService` that records calls and fires
/// nothing.
///
/// Used by goldens and integration/widget tests (overriding
/// `hapticServiceProvider`) so a tap under test never reaches the platform
/// `HapticFeedback` channel and stays deterministic. NOT a production default:
/// the production path uses `DeviceHapticService` (the local device is the
/// backend). Unlike the const no-backend defaults elsewhere, this adapter is
/// stateful because it records the call history for assertions; construct a
/// fresh instance per test/preview.
///
/// Haptics are fire-and-forget with no user-facing success to fake, so this
/// adapter does not surface an "unavailable" state — it simply records and
/// returns (C2 / C13: never fakes a success that has no backend, and there is
/// no success state to fake here).
final class NoopHapticService implements HapticService {
  NoopHapticService();

  final List<HapticKind> _calls = <HapticKind>[];

  /// The most recent [HapticKind] triggered, or `null` if `trigger` was never
  /// called. The primary assertion handle for tests.
  HapticKind? lastKind;

  /// The number of times `trigger` has been called.
  int callCount = 0;

  /// An unmodifiable view of every [HapticKind] triggered, in call order.
  List<HapticKind> get calls => List.unmodifiable(_calls);

  @override
  Future<void> trigger(HapticKind kind) async {
    _calls.add(kind);
    lastKind = kind;
    callCount += 1;
  }
}
