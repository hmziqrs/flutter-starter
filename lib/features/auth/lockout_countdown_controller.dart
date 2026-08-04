import 'dart:async';

import 'package:flutter/foundation.dart';

class LockoutCountdownController extends ValueNotifier<int> {
  LockoutCountdownController() : super(0);

  Timer? _timer;
  bool _disposed = false;

  int get remainingSeconds => value;

  void syncFrom(int seconds) {
    _timer?.cancel();
    value = seconds < 0 ? 0 : seconds;
    if (value <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_disposed) return;
    if (value > 0) value -= 1;
    if (value <= 0) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
