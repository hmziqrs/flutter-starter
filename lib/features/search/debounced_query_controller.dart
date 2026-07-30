import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debounce window before a typed query is published to listeners; kept just
/// under the perception threshold so the field feels live without flooding
/// the matcher on every keystroke.
const debounceQueryDuration = Duration(milliseconds: 250);

/// Debounces raw search-box input and publishes only the settled query.
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

  /// Clears the query immediately (no debounce), e.g. for a clear affordance.
  void clear() {
    _timer?.cancel();
    _pending = '';
    if (state != '') {
      state = '';
    }
  }
}
