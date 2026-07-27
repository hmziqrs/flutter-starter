import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/error_reporting/recording_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

/// The crash-reporting spec requires the `installErrorHandlers` install site
/// (the load-bearing wiring that funnels BOTH FlutterError.onError AND
/// PlatformDispatcher.onError to BOTH AppLogger.error AND the CrashReporter) to
/// be under test. These tests drive the installed handlers directly with a
/// [RecordingCrashReporter] and assert both error sources reach the reporter
/// with the correct source tag, and that the platform handler swallows
/// (returns true) so errors never re-propagate.
///
/// The reporter is called in the same closure as `logger.error`, immediately
/// after it with no early return, so a passing reporter assertion transitively
/// proves the logger path also executed. AppLogger is a concrete final class
/// with no injectable sink, so the reporter is the observable seam.
void main() {
  group('installErrorHandlers', () {
    void Function(FlutterErrorDetails)? previousFlutterOnError;
    bool Function(Object, StackTrace)? previousPlatformOnError;

    setUp(() {
      previousFlutterOnError = FlutterError.onError;
      previousPlatformOnError = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = previousFlutterOnError;
      PlatformDispatcher.instance.onError = previousPlatformOnError;
    });

    // The handler captures are fire-and-forget (unawaited inside the install);
    // yield one event-loop turn so the reporter's async body completes before
    // asserting.
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('routes Flutter framework errors to the crash reporter', () async {
      final reporter = RecordingCrashReporter(verbose: false);
      installErrorHandlers(AppLogger(verbose: true), reporter);

      FlutterError.onError?.call(
        FlutterErrorDetails(
          exception: Exception('flutter boom'),
          stack: StackTrace.current,
        ),
      );
      await settle();

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.context['source'], 'flutter_framework');
      // The redacted message still carries the exception text (no tokens to
      // scrub here), proving the payload flowed end to end.
      expect(reporter.reports.single.message, contains('Exception'));
    });

    test('routes platform errors to the reporter and swallows them', () async {
      final reporter = RecordingCrashReporter(verbose: false);
      installErrorHandlers(AppLogger(verbose: true), reporter);

      final swallowed = PlatformDispatcher.instance.onError?.call(
        StateError('platform boom'),
        StackTrace.current,
      );
      await settle();

      // The platform handler must return true so the framework treats the
      // error as handled — never rethrows / propagates.
      expect(swallowed, true);
      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.context['source'], 'platform');
      expect(reporter.reports.single.message, contains('platform boom'));
    });

    test('wires both handlers; each error source is reported exactly once', () async {
      final reporter = RecordingCrashReporter(verbose: false);
      installErrorHandlers(AppLogger(verbose: true), reporter);

      FlutterError.onError?.call(FlutterErrorDetails(exception: Exception('flutter')));
      PlatformDispatcher.instance.onError?.call(StateError('platform'), StackTrace.empty);
      await settle();

      expect(
        reporter.reports.map((r) => r.context['source']),
        <String?>['flutter_framework', 'platform'],
      );
    });
  });
}
