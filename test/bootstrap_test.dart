import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/startup/startup_error_view.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/error_reporting/recording_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

void main() {
  group('bootstrapApplication', () {
    test('renders the startup-failure UI when config loading throws', () async {
      Widget? rendered;
      await bootstrapApplication(runApplication: (application) => rendered = application);

      expect(rendered, isA<StartupErrorApp>());
    });
  });

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

    /// `AppLogger` is a `final class` owning a private Talker, so the recording
    /// double captures its console sink in a print-intercepting zone.
    Future<List<String>> captureLoggerSink(Future<void> Function() body) async {
      final lines = <String>[];
      await runZonedGuarded(
        body,
        (error, stackTrace) {},
        zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => lines.add(line)),
      );
      return lines;
    }

    test('the logger.error sink fires alongside the reporter for every error source', () async {
      final reporter = RecordingCrashReporter(verbose: false);
      final lines = await captureLoggerSink(() async {
        installErrorHandlers(AppLogger(verbose: true), reporter);

        FlutterError.onError?.call(
          FlutterErrorDetails(exception: Exception('flutter boom'), stack: StackTrace.current),
        );
        PlatformDispatcher.instance.onError?.call(
          StateError('platform boom'),
          StackTrace.current,
        );
      });

      expect(reporter.reports, hasLength(2));
      expect(lines, anyElement(contains('Flutter framework error')));
      expect(lines, anyElement(contains('Uncaught platform error')));
    });
  });
}
