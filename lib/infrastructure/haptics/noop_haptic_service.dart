import 'package:starter/infrastructure/haptics/haptic_service.dart';

/// Deterministic `HapticService` that records calls and fires nothing. Used
/// by goldens and tests (overriding `hapticServiceProvider`); NOT the
/// production default (`DeviceHapticService`). Stateful — records call
/// history for assertions, so construct a fresh instance per test/preview.
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
