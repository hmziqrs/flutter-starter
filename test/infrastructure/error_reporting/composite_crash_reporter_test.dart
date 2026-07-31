import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/error_reporting/composite_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/recording_crash_reporter.dart';

class _ThrowingCrashReporter implements CrashReporter {
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    throw StateError('crash boom');
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    throw StateError('crash boom');
  }
}

void main() {
  group('CompositeCrashReporter', () {
    test('is a CrashReporter', () {
      expect(CompositeCrashReporter(const []), isA<CrashReporter>());
    });

    test('fans recordError out to every backend', () async {
      final first = RecordingCrashReporter(verbose: false);
      final second = RecordingCrashReporter(verbose: false);
      final composite = CompositeCrashReporter([first, second]);

      await composite.recordError(
        Exception('boom'),
        StackTrace.current,
        context: <String, Object?>{'source': 'platform'},
      );

      expect(first.reports, hasLength(1));
      expect(second.reports, hasLength(1));
      expect(first.reports.single.message, second.reports.single.message);
      expect(first.reports.single.context['source'], 'platform');
    });

    test('fans recordFlutterError out to every backend', () async {
      final first = RecordingCrashReporter(verbose: false);
      final second = RecordingCrashReporter(verbose: false);
      final composite = CompositeCrashReporter([first, second]);

      await composite.recordFlutterError(
        FlutterErrorDetails(exception: Exception('flutter boom')),
      );

      expect(first.reports, hasLength(1));
      expect(second.reports, hasLength(1));
      expect(first.reports.single.context['source'], 'flutter_framework');
    });

    test('a throwing backend never blocks the remaining backends', () async {
      final healthy = RecordingCrashReporter(verbose: false);
      final composite = CompositeCrashReporter([
        _ThrowingCrashReporter(),
        healthy,
        _ThrowingCrashReporter(),
      ]);

      await expectLater(
        composite.recordError(
          Exception('boom'),
          StackTrace.current,
          context: <String, Object?>{'source': 'platform'},
        ),
        completes,
      );
      await expectLater(
        composite.recordFlutterError(
          FlutterErrorDetails(exception: Exception('flutter boom')),
        ),
        completes,
      );

      expect(healthy.reports, hasLength(2));
      expect(healthy.reports.first.context['source'], 'platform');
      expect(healthy.reports.last.context['source'], 'flutter_framework');
    });

    test('an empty delegate list never throws', () async {
      final composite = CompositeCrashReporter(const []);
      await expectLater(
        composite.recordError(Exception('boom'), StackTrace.current),
        completes,
      );
      await expectLater(
        composite.recordFlutterError(
          FlutterErrorDetails(exception: Exception('boom')),
        ),
        completes,
      );
    });
  });
}
