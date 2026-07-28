import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The debounce window before a typed query is published to listeners. The
/// feature spec pins "~250 ms"; a value just under the perception threshold so
/// the field feels live without flooding the matcher on every keystroke.
const debounceQueryDuration = Duration(milliseconds: 250);

/// Hand-written Riverpod [NotifierProvider] that debounces the raw search-box
/// input and publishes only the settled query.
///
/// Self-contained (no production override; override only in tests via
/// `FakeAsync` / provider override). The state is the published (debounced)
/// query string; the in-flight query is held in a private field and cancelled
/// on each new keystroke, so only the final value within the window ever
/// publishes — intermediate values are dropped (feature spec: "emits only after
/// the debounce window and drops stale values").
///
/// The [Timer] respects the test zone's fake clock (`package:fake_async`
/// intercepts `Timer`), so unit tests assert the debounce deterministically
/// without wall-clock flakiness. Navigation never gates on the timer — the
/// search page reads the published value and rebuilds results when it changes.
final debouncedQueryProvider = NotifierProvider<DebouncedQueryController, String>(
  DebouncedQueryController.new,
);

final class DebouncedQueryController extends Notifier<String> {
  Timer? _timer;

  /// The most recent raw input. Held separately from the published [state] so a
  /// cancelled timer never publishes a stale value: only when the window elapses
  /// without a new keystroke does [_pending] become [state].
  String _pending = '';

  @override
  String build() {
    // Cancel the in-flight timer if the element is disposed (search route
    // popped) so a backgrounded page never publishes after teardown.
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  /// Accepts the raw search-box text and (re)starts the debounce window. The
  /// published [state] is unchanged until [debounceQueryDuration] elapses with
  /// no further input; each call cancels the prior timer so only the latest
  /// value can publish.
  void set(String query) {
    _pending = query;
    _timer?.cancel();
    _timer = Timer(debounceQueryDuration, () {
      if (state != _pending) {
        state = _pending;
      }
    });
  }

  /// Empties both the in-flight query and the published state immediately (no
  /// debounce) — used by the clear affordance so the list returns to "show all"
  /// without waiting for the window.
  void clear() {
    _timer?.cancel();
    _pending = '';
    if (state != '') {
      state = '';
    }
  }
}
