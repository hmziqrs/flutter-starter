import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

mixin SettingsSaveFailureState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool saveFailed = false;

  /// Runs a settings write, surfacing failure as [saveFailed] for the tile to
  /// render. The failure is also logged: the controller rethrows, so this catch
  /// is where the signal would otherwise be lost entirely.
  Future<void> runSave(Future<void> Function() operation) async {
    final logger = ref.read(appLoggerProvider);
    try {
      await operation();
      if (mounted) setState(() => saveFailed = false);
    } on Object catch (error, stackTrace) {
      logger.warning(
        'settings.save_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'tile': '$T'},
      );
      if (mounted) setState(() => saveFailed = true);
    }
  }
}
