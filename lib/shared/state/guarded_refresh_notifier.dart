import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

/// Adds epoch-guarded refresh semantics to a [Notifier].
///
/// A monotonically increasing live epoch is bumped ([bumpLiveEpoch]) whenever an
/// external mutation invalidates in-flight loads. [guardedRefresh] captures the
/// epoch at start and discards any completion that lands after a bump, so a
/// stale load can never overwrite fresher state. Failures are reported through
/// [logger] and swallowed — refresh never throws to callers.
mixin GuardedRefreshNotifier<T> on Notifier<T> {
  int _liveEpoch = 0;

  /// Bump the live epoch, invalidating any in-flight guarded refresh.
  void bumpLiveEpoch() => _liveEpoch++;

  /// Logger used to record swallowed refresh failures.
  AppLogger get logger;

  /// Load a value via [load] and, on a successful non-stale completion, hand it
  /// to [apply].
  ///
  /// The epoch is captured before [load] runs; if it has since been bumped the
  /// completion is stale and [apply] is skipped. Any [Object] thrown by [load]
  /// is reported via [logger] as [errorMessage] (with the captured stack trace)
  /// and swallowed so callers never observe a refresh-time error.
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
