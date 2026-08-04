import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

mixin GuardedRefreshNotifier<T> on Notifier<T> {
  int _liveEpoch = 0;

  void bumpLiveEpoch() => _liveEpoch++;

  AppLogger get logger;

  Future<void> guardedRefresh<U>({
    required Future<U> Function() load,
    required void Function(U loaded) apply,
    required String errorMessage,
  }) async {
    final epochAtStart = _liveEpoch;
    try {
      final loaded = await load();
      if (epochAtStart == _liveEpoch) {
        apply(loaded);
      }
    } on Object catch (error, stackTrace) {
      logger.warning(
        errorMessage,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
