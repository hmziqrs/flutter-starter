import 'package:starter/infrastructure/haptics/haptic_service.dart';

final class NoopHapticService implements HapticService {
  NoopHapticService();

  final List<HapticKind> _calls = <HapticKind>[];

  HapticKind? lastKind;

  int callCount = 0;

  List<HapticKind> get calls => List.unmodifiable(_calls);

  @override
  Future<void> trigger(HapticKind kind) async {
    _calls.add(kind);
    lastKind = kind;
    callCount += 1;
  }
}
