import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const debounceQueryDuration = Duration(milliseconds: 250);

final debouncedQueryProvider = NotifierProvider<DebouncedQueryController, String>(
  DebouncedQueryController.new,
);

final class DebouncedQueryController extends Notifier<String> {
  Timer? _timer;
  String _pending = '';

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  void set(String query) {
    _pending = query;
    _timer?.cancel();
    _timer = Timer(debounceQueryDuration, () {
      if (state != _pending) {
        state = _pending;
      }
    });
  }

  void clear() {
    _timer?.cancel();
    _pending = '';
    if (state != '') {
      state = '';
    }
  }
}
