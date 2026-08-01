import 'package:starter/infrastructure/logging/app_logger.dart';

/// Runs [action] and absorbs any failure, reporting it through [logger].
///
/// Returns the action's result, or `null` if it threw. The `on Object` clause
/// satisfies `avoid_catches_without_on_clauses` while still catching everything
/// (both `Exception` and `Error` subtypes), keeping the fire-and-forget contract
/// explicit and observable instead of a bare `// ignored`.
///
/// Prefer this over an ad-hoc `try`/`on Object {}` wherever a swallowed error
/// would otherwise hide a real bug: startup wiring, mid-tier platform adapters,
/// and best-effort persistence. Subsystems that must never log their own
/// failures (crash reporters, analytics fan-outs) should keep an explicit,
/// documented catch instead.
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
