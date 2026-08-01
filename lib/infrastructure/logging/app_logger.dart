import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';
import 'package:talker_flutter/talker_flutter.dart';

final class AppLogger {
  AppLogger({required bool verbose, this._redactor = const LogRedactor()})
    : _verbose = verbose,
      _talker = Talker(
        settings: TalkerSettings(
          useHistory: verbose,
          maxHistoryItems: verbose ? 500 : 50,
        ),
      );

  factory AppLogger.bootstrap() => AppLogger(verbose: false);

  final bool _verbose;
  final LogRedactor _redactor;
  final Talker _talker;

  void debug(String message, {Map<String, Object?> context = const {}}) {
    if (!_verbose) {
      return;
    }

    _talker.debug(_format(message, context));
  }

  void info(String message, {Map<String, Object?> context = const {}}) {
    _talker.info(_format(message, context));
  }

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    final errorText = error == null ? null : _redactor.redactText(error.toString());
    final formatted = _format(
      message,
      <String, Object?>{
        ...context,
        'error': ?errorText,
      },
    );
    _talker.warning(formatted, null, _verbose ? stackTrace : null);
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    final errorText = error == null ? null : _redactor.redactText(error.toString());
    final formatted = _format(
      message,
      <String, Object?>{
        ...context,
        'error': ?errorText,
      },
    );
    _talker.error(formatted, null, _verbose ? stackTrace : null);
  }

  String _format(String message, Map<String, Object?> context) {
    final redactedMessage = _redactor.redactText(message);
    if (context.isEmpty) {
      return redactedMessage;
    }

    return '$redactedMessage | ${_redactor.redactContext(context)}';
  }
}

/// Shared diagnostic logger for Riverpod consumers.
///
/// Overridden at the composition root with the application's real [AppLogger]
/// when one is available; otherwise falls back to a non-verbose instance.
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.bootstrap());
