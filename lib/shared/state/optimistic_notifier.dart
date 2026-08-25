import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin OptimisticNotifier<T> on Notifier<T> {
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
