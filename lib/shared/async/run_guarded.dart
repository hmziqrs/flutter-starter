import 'package:starter/infrastructure/logging/app_logger.dart';

/// Runs [action] and returns null on failure, reporting it (including [Error])
/// via [logger]; use for fire-and-forget paths where a swallowed failure masks a bug.
Future<T?> runGuarded<T>(
  Future<T> Function() action, {
  required AppLogger logger,
  required String label,
  Map<String, Object?> context = const {},
}) async {
  try {
    return await action();
  } on Object catch (error, stackTrace) {
    logger.warning(label, error: error, stackTrace: stackTrace, context: context);
    return null;
  }
}
