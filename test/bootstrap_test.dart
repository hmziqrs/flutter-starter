import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';
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

  group('bootstrap production error path', () {
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

    test('with a backend configured, the installed handlers carry the HTTP reporter', () async {
      final previousPrefs = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previousPrefs);
      PackageInfo.setMockInitialValues(
        appName: 'starter',
        packageName: 'starter',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      // The stand-in crash backend: records POSTed bodies, answers 204.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final postedBodies = <String>[];
      final servedRequests = server.listen((request) async {
        postedBodies.add(await utf8.decoder.bind(request).join());
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      });
      addTearDown(() async {
        await servedRequests.cancel();
        await server.close(force: true);
      });

      // The tester self-reports as android, which would probe the android TV
      // capability channel; pin the desktop platform like the wiring tests.
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      Widget? rendered;
      try {
        await bootstrap(
          AppConfig(
            environment: AppEnvironment.development,
            enableVerboseLogging: false,
            enableDevTools: false,
            iosAppleId: '',
            allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
            backendBaseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
          ),
          runApplication: (application) => rendered = application,
        );
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }
      expect(rendered, isA<App>());

      // No hand-wiring: the error must travel through the handlers bootstrap
      // installed from `AppDependencies.production` to the configured backend.
      FlutterError.onError?.call(
        FlutterErrorDetails(
          exception: StateError('bootstrap production boom'),
          stack: StackTrace.current,
        ),
      );

      var arrived = false;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (postedBodies.any((body) => body.contains('bootstrap production boom'))) {
          arrived = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(
        arrived,
        isTrue,
        reason: 'production-with-backend must install an HTTP-reporting composite',
      );
    });

    test('zoned application errors reach the re-armed composite through the sink', () async {
      final previousPrefs = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previousPrefs);
      PackageInfo.setMockInitialValues(
        appName: 'starter',
        packageName: 'starter',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final postedBodies = <String>[];
      final servedRequests = server.listen((request) async {
        postedBodies.add(await utf8.decoder.bind(request).join());
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      });
      addTearDown(() async {
        await servedRequests.cancel();
        await server.close(force: true);
      });

      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      // The production shape: bootstrapApplication creates the sink, its zone
      // handler reports through it, and installErrorHandlers swaps in each
      // reporter — ending at the production composite after the re-arm.
      final zonedCrashSink = ZonedCrashSink();
      try {
        await bootstrap(
          AppConfig(
            environment: AppEnvironment.development,
            enableVerboseLogging: false,
            enableDevTools: false,
            iosAppleId: '',
            allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
            backendBaseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
          ),
          runApplication: (_) {},
          zonedCrashSink: zonedCrashSink,
        );
      } finally {
        debugDefaultTargetPlatformOverride = previousPlatform;
      }

      // Mirror the zone handler's body: an uncaught async error inside the
      // app zone lands here (never at the platform handler), and must reach
      // the backend through the swapped-in composite. runZonedGuarded's
      // returned future never completes for an async throw (the zone consumes
      // the error), so the handler completes a completer instead.
      final handled = Completer<void>();
      unawaited(
        runZonedGuarded<Future<void>>(
              () async {
                await Future<void>.value();
                throw StateError('zoned production boom');
              },
              (error, stackTrace) {
                unawaited(zonedCrashSink.report(error, stackTrace));
                handled.complete();
              },
            ) ??
            Future<void>.value(),
      );
      await handled.future.timeout(const Duration(seconds: 5));

      var arrived = false;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (postedBodies.any(
          (body) => body.contains('zoned production boom') && body.contains('zone'),
        )) {
          arrived = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(
        arrived,
        isTrue,
        reason: 'zone-guarded errors must reach the re-armed production composite',
      );
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
