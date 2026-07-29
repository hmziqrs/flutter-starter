import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/firebase_crashlytics_crash_reporter.dart';

void main() {
  group('FirebaseCrashlyticsCrashReporter', () {
    // Firebase is intentionally NOT initialized in this suite (no
    // Firebase.initializeApp), so resolving FirebaseCrashlytics.instance throws
    // [core/no-app]. The adapter's guarded _resolve swallows that and the report
    // becomes a no-op. The contract under test is that recordError stays total —
    // a reporter must never break the error path it observes — on every
    // platform, mirroring SentryCrashReporter's discipline.

    test('is a CrashReporter', () {
      expect(
        FirebaseCrashlyticsCrashReporter(verbose: false),
        isA<CrashReporter>(),
      );
    });

    test('recordError never rethrows when the SDK is unavailable', () async {
      final reporter = FirebaseCrashlyticsCrashReporter(verbose: false);
      await expectLater(
        reporter.recordError(
          Exception('boom'),
          StackTrace.current,
          context: <String, Object?>{'request_id': 'request-1'},
        ),
        completes,
      );
    });

    test('recordFlutterError never rethrows when the SDK is unavailable', () async {
      final reporter = FirebaseCrashlyticsCrashReporter(verbose: true);
      await expectLater(
        reporter.recordFlutterError(
          FlutterErrorDetails(exception: Exception('boom')),
        ),
        completes,
      );
    });

    test('a token-shaped error never throws (redaction choke point stays total)', () async {
      final reporter = FirebaseCrashlyticsCrashReporter(verbose: false);
      await expectLater(
        reporter.recordError(
          Exception('bearer token=eyJhbGciOi.example-token'),
          StackTrace.current,
        ),
        completes,
      );
    });

    group('on an unsupported platform (Linux)', () {
      TargetPlatform? previous;

      setUp(() => previous = debugDefaultTargetPlatformOverride);
      tearDown(() => debugDefaultTargetPlatformOverride = previous);

      test('every method early-returns and never throws', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final reporter = FirebaseCrashlyticsCrashReporter(verbose: false);

        await expectLater(
          reporter.recordError(Exception('boom'), StackTrace.current),
          completes,
        );
        await expectLater(
          reporter.recordFlutterError(
            FlutterErrorDetails(exception: Exception('boom')),
          ),
          completes,
        );
      });
    });
  });
}
