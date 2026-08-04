import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adds optimistic-update rollback semantics to a [Notifier].
///
/// [guardRollback] snapshots the current state, publishes the optimistic
/// candidate, then awaits a confirming async body. If that body throws
/// anything, the prior state is restored and the error is rethrown — so
/// listeners observe a transient optimistic update followed by a revert on
/// failure.
mixin OptimisticNotifier<T> on Notifier<T> {
  /// Apply [next] optimistically and confirm it with [body].
  ///
  /// The current state is captured as the rollback target, [next] is
  /// published immediately, and [body] is awaited. On any [Object] thrown by
  /// [body] the captured state is restored and the error is rethrown.
  Future<void> guardRollback(T next, Future<void> Function() body) async {
    final previous = state;
    state = next;
    try {
      await body();
    } on Object {
      state = previous;
      rethrow;
    }
  }
}
