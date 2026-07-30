// End-to-end coverage that drives the app's REAL HTTP clients against the live
// Hono dummy server (`tools/hono_server`). This is a cross-framework contract
// check: a Dart `dart:io` client speaking to a JavaScript Hono backend over a
// real loopback socket. No client is stubbed here — the point is the live
// round-trip plus the honest-degradation contract (C2: degrade, never fake).
//
// The whole group is SKIPPED (not failed) on hosts without a JS runtime so CI
// that lacks bun/Node does not go red; it runs and must pass wherever bun is
// installed, which is the repo's documented runtime.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/experiments/deterministic_experiment_source.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/force_update/remote_config_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/infrastructure/auth/http_auth_client.dart';
import 'package:starter/infrastructure/auth/http_otp_client.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/notifications/http_notifications_registration_client.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';
import 'package:starter/infrastructure/remote_config/remote_config_experiment_source.dart';
import 'package:starter/infrastructure/remote_config/remote_config_feature_flags_source.dart';

/// Resolved JS runtime command for booting the Hono server.
///
/// `executable` is what `Process.start` invokes; `prefixArgs` is the argv that
/// precedes the server script path (`const []` for bun, `const ['tsx']` for the
/// `npx tsx` fallback).
final class _JsRuntime {
  const _JsRuntime({required this.executable, required this.prefixArgs});

  final String executable;
  final List<String> prefixArgs;

  /// Full argv list (executable first) for `Process.start` to launch the server
  /// on [port]. Caller passes `command(...).first` as the executable and the
  /// remaining entries as the arguments.
  List<String> command(String script, int port) => [
    executable,
    ...prefixArgs,
    script,
    '--port',
    '$port',
  ];

  /// Detects bun (preferred) on `PATH`, then `~/.bun/bin/bun`, then `npx tsx`.
  /// Returns `null` when no JS runtime is reachable so the caller can skip.
  static _JsRuntime? resolve() {
    // 1. bun somewhere on PATH.
    if (_probe('bun', const ['--version'])) {
      return const _JsRuntime(executable: 'bun', prefixArgs: []);
    }
    // 2. bun installed at its well-known location but not on PATH (common when
    //    `flutter test` is launched with a sanitized environment).
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final bunPath = _join(home, '.bun', 'bin', 'bun');
      if (File(bunPath).existsSync() && _probe(bunPath, const ['--version'])) {
        return _JsRuntime(executable: bunPath, prefixArgs: const []);
      }
    }
    // 3. Node via npx tsx (downloads tsx on demand).
    if (_probe('npx', const ['--version'])) {
      return const _JsRuntime(executable: 'npx', prefixArgs: ['tsx']);
    }
    return null;
  }

  static bool _probe(String exe, List<String> args) {
    try {
      final result = Process.runSync(exe, args);
      return result.exitCode == 0;
    } on Object {
      // ProcessException (not found / cannot exec) — try the next candidate.
      return false;
    }
  }
}

/// A live Hono server booted in a subprocess.
///
/// `start` binds a free port, spawns the runtime pointed at the server script,
/// and does not return until `GET /healthz` answers 200 (or the readiness
/// deadline elapses, in which case it tears down and throws). `close` SIGTERMs
/// the process and force-kills it if it lingers — always best-effort and safe
/// to call from a `tearDown`.
final class _HonoServerHandle {
  _HonoServerHandle._({required this.process, required this.port});

  final Process process;
  final int port;

  static Future<_HonoServerHandle> start({
    required _JsRuntime runtime,
    required String script,
    required String workingDirectory,
  }) async {
    final port = await _freePort();
    final argv = runtime.command(script, port);
    final process = await Process.start(
      argv.first,
      argv.skip(1).toList(),
      workingDirectory: workingDirectory,
    );

    final stdoutLines = <String>[];
    final stderrLines = <String>[];
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(stdoutLines.add);
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(stderrLines.add);

    final healthUri = Uri.parse('http://127.0.0.1:$port/healthz');
    final ready = await _waitForReady(process: process, healthUri: healthUri);
    if (!ready) {
      // Best-effort cleanup before surfacing the failure.
      process.kill(ProcessSignal.sigkill);
      await _exitOrKill(process);
      final stdoutDump = stdoutLines.join('\n');
      final stderrDump = stderrLines.join('\n');
      throw StateError(
        'Hono server never became ready on port $port '
        '(ran: ${argv.join(' ')}).\n'
        'stdout:\n$stdoutDump\n'
        'stderr:\n$stderrDump',
      );
    }
    return _HonoServerHandle._(process: process, port: port);
  }

  Future<void> close() async {
    try {
      process.kill(); // SIGTERM is the default; escalates to SIGKILL below if it lingers.
    } on Object {
      // Already gone — nothing to signal.
    }
    await _exitOrKill(process);
  }
}

void main() {
  final runtime = _JsRuntime.resolve();
  final repoRoot = _resolveRepoRoot();
  final serverScript = _join(repoRoot, 'tools', 'hono_server', 'src', 'index.ts');

  group('hono server e2e (real dart:http <-> live JS Hono)', () {
    if (runtime == null) {
      test(
        'skipped: no JS runtime (bun or npx tsx) available',
        () {},
        skip: 'no JS runtime (bun or npx tsx) available on PATH',
      );
      return;
    }

    _HonoServerHandle? server;
    // Tests run only after a successful setUpAll, so this is always initialized
    // by the time any test body reads it. Kept as a top-level group local so the
    // failure-path test can still reference a deliberately wrong URL.
    late final Uri baseUri;
    // Real auth/OTP adapters over a shared Dio (the composition-root shape) so
    // the auth tests exercise the live dart:io <-> JS Hono loopback socket.
    late HttpAuthClient authClient;
    late HttpOtpClient otpClient;

    setUpAll(() async {
      final handle = await _HonoServerHandle.start(
        runtime: runtime,
        script: serverScript,
        workingDirectory: repoRoot,
      );
      server = handle;
      baseUri = Uri.parse('http://127.0.0.1:${handle.port}');
      final dio = buildAppDio(baseUri);
      authClient = HttpAuthClient(baseUrl: baseUri, dio: dio);
      otpClient = HttpOtpClient(baseUrl: baseUri, dio: dio);
    });

    tearDownAll(() async {
      // setUpAll may have thrown before assigning [server]; tear down only what
      // actually came up so a setup failure doesn't cascade into a
      // LateInitializationError.
      final handle = server;
      if (handle != null) {
        await handle.close();
      }
    });

    test('remote-config fetch round-trips and parses into typed slices', () async {
      final client = RemoteConfigClient(baseUrl: baseUri);
      final payload = await client.fetch(
        const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      );
      expect(payload, isNotNull, reason: 'fetch must succeed against the live server');
      final parsed = payload!;
      expect(parsed.flags, isNotNull, reason: 'flags slice present');
      expect(parsed.versionPolicy, isNotNull, reason: 'versionPolicy slice present');
      expect(parsed.experiments, isNotNull, reason: 'experiments slice present');
      expect(parsed.revision, '1', reason: 'server serves revision "1"');
    });

    test('feature-flags source loads from the live flags slice', () async {
      const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');
      final source = RemoteConfigFeatureFlagsSource(
        baseUrl: baseUri,
        buildInfo: buildInfo,
      );
      // The server serves an empty flags slice -> defaults baseline.
      final flags = await source.load();
      expect(flags, const FeatureFlags.defaults());
    });

    test('version-gate degrades to none when the policy has no storeUrl', () async {
      final store = RemoteConfigVersionGateStore(baseUrl: baseUri);
      // The server's default versionPolicy has null thresholds + null storeUrl.
      // No storeUrl means we cannot offer an update path -> UpdateRequirementNone.
      final result = await store.check(
        const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      );
      expect(result, const UpdateRequirementNone());
      expect(store.storeUrl, isNull);
    });

    test('experiments source returns an assignment without throwing', () async {
      const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');
      final source = RemoteConfigExperimentSource(
        baseUrl: baseUri,
        buildInfo: buildInfo,
        fallback: DeterministicExperimentSource(store: InMemorySettingsStore()),
      );
      // The server serves an empty experiments slice -> degrade to the local
      // deterministic fallback. The point: no throw, a real assignment comes back.
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.key, ExperimentKey.paywallLayout);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });

    test(
      'notifications registration client round-trips register/unregister/permission-revoked',
      () async {
        final client = HttpNotificationsRegistrationClient(baseUrl: baseUri);
        await expectLater(
          client.registerToken(token: 'e2e-token', platform: 'ios', deviceId: 'e2e-device'),
          completes,
        );
        await expectLater(client.unregisterToken('e2e-token'), completes);
        await expectLater(
          client.reportPermissionRevoked(deviceId: 'e2e-device'),
          completes,
        );
      },
    );

    // Auth (register -> OTP verify -> login -> refresh -> logout) driving the
    // REAL HttpAuthClient / HttpOtpClient against the live Hono server. This is
    // the cross-framework session/OTP contract check: a JS backend must satisfy
    // the same C9 contract the Dart shelf server does. Mirrors
    // test/infrastructure/auth/http_auth_client_test.dart. Each test mutates
    // server-side account/token state, so unique emails keep them independent.
    var authEmailSeq = 0;
    String authEmail() => 'hono-e2e-${authEmailSeq++}@example.com';

    test('register returns an OtpIssueResult with attemptToken + sms channel', () async {
      final result = await authClient.register(
        credentials: AuthCredentials(email: authEmail(), password: 'Password1'),
        displayName: 'Sam Rivera',
      );
      expect(result.attemptToken, isNotEmpty);
      expect(result.channel, OtpDeliveryChannel.sms);
      expect(result.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('login exchanges credentials for an authenticated session', () async {
      final session = await authClient.login(
        AuthCredentials(email: authEmail(), password: 'Password1'),
      );
      expect(session, isA<AuthAuthenticated>());
      final auth = session as AuthAuthenticated;
      expect(auth.accessToken, isNotEmpty);
      expect(auth.refreshToken, isNotEmpty);
      expect(auth.userId, isNotEmpty);
      expect(auth.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('registration verify with the dev code returns a valid, non-null session', () async {
      final email = authEmail();
      // register creates the pending account; the OTP client then issues a fresh
      // code it can verify (the register + OTP clients hold their own
      // attempt-token state, exactly as the app's register -> OTP pages do).
      await authClient.register(
        credentials: AuthCredentials(email: email, password: 'Password1'),
        displayName: 'Sam Rivera',
      );
      await otpClient.issue(purpose: OtpPurpose.registration, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isA<AuthAuthenticated>());
      expect(result.session!.accessToken, isNotEmpty);
      expect(result.session!.refreshToken, isNotEmpty);
      expect(result.session!.userId, isNotEmpty);
    });

    test('a non-registration verify returns valid with a null session', () async {
      final email = authEmail();
      await otpClient.issue(purpose: OtpPurpose.mfa, identifier: email);
      final result = await otpClient.verify(identifier: email, code: '123456');
      expect(result.outcome, OtpVerifyOutcome.valid);
      expect(result.session, isNull, reason: 'mfa purpose issues no session tokens');
    });

    test('refresh rotates the token and inherits userId', () async {
      final email = authEmail();
      final session = await authClient.login(AuthCredentials(email: email, password: 'Password1'));
      final refreshed = await authClient.refresh(session);
      expect(refreshed, isA<AuthAuthenticated>());
      final auth = refreshed as AuthAuthenticated;
      final prior = session as AuthAuthenticated;
      expect(auth.accessToken, isNotEmpty);
      expect(auth.refreshToken, isNot(prior.refreshToken));
      expect(auth.userId, prior.userId, reason: 'userId is inherited across rotations');
    });

    test('logout returns anonymous', () async {
      final email = authEmail();
      final session = await authClient.login(AuthCredentials(email: email, password: 'Password1'));
      expect(await authClient.logout(session), isA<AuthAnonymous>());
    });

    test('honest-degradation: an unreachable backend yields null, never throws', () async {
      final badClient = RemoteConfigClient(
        baseUrl: Uri.parse('http://127.0.0.1:1'), // unroutable -> connect failure
        timeout: const Duration(milliseconds: 500),
      );
      final payload = await badClient.fetch(
        const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      );
      expect(payload, isNull, reason: 'RemoteConfigClient must degrade to null (C2)');
    });
  });
}

// ----------------------------- harness helpers -----------------------------

/// Picks a free TCP port by binding to port 0 on loopback, reading the assigned
/// port, then closing the socket. Never returns a fixed/hard-coded port.
Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// Polls `healthUri` until it answers 200, the [process] exits, or the ~10s
/// readiness deadline elapses. Returns `true` only on a successful 200.
Future<bool> _waitForReady({required Process process, required Uri healthUri}) async {
  var exited = false;
  // Process.exitCode never throws, so this watcher is safe to leave unawaited.
  unawaited(process.exitCode.then((_) => exited = true));

  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    if (exited) return false;
    if (await _healthOk(healthUri)) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return false;
}

/// Single-shot `GET /healthz` probe. Returns `true` only on HTTP 200; swallows
/// any network/timeout failure so the poll loop can retry.
Future<bool> _healthOk(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 1));
    final response = await request.close().timeout(const Duration(seconds: 1));
    await response.drain<void>().timeout(const Duration(seconds: 1));
    return response.statusCode == HttpStatus.ok;
  } on Object {
    return false;
  } finally {
    client.close(force: true);
  }
}

/// Waits for [process] to exit (up to 5s after SIGTERM), then SIGKILLs it if it
/// lingers. Always returns the exit code so callers can `await` unconditional
/// cleanup inside a `tearDown`.
Future<int> _exitOrKill(Process process) async {
  try {
    return await process.exitCode.timeout(const Duration(seconds: 5));
  } on TimeoutException {
    try {
      process.kill(ProcessSignal.sigkill);
    } on Object {
      // Already gone.
    }
    return process.exitCode;
  }
}

/// Resolves the repo root either from `Directory.current` (flutter test runs
/// there) or — if that doesn't look like the repo — from this test file's
/// location on disk.
String _resolveRepoRoot() {
  final current = Directory.current;
  if (Directory(_join(current.path, 'tools', 'hono_server')).existsSync()) {
    return current.path;
  }
  try {
    final scriptFile = File(Platform.script.toFilePath());
    // test/e2e/hono_server_e2e_test.dart -> three `.parent`s up to repo root.
    return scriptFile.parent.parent.parent.path;
  } on Object {
    return current.path;
  }
}

/// Joins path segments with `/`. Avoids pulling in `package:path` (not a direct
/// dependency). Dart's `File`/`Directory`/`Process.start(workingDirectory:)`
/// accept forward slashes on every host platform, so this is sufficient for the
/// harness's Unix-style fixture paths.
String _join(String a, String b, [String? c, String? d, String? e]) {
  var result = a;
  for (final part in [b, c, d, e]) {
    if (part == null) break;
    if (result.endsWith('/')) {
      result = '$result$part';
    } else {
      result = '$result/$part';
    }
  }
  return result;
}
