// Test harness that boots the REAL in-repo Dart test server
// (`tools/test_server`) on a free port as a subprocess. Adapted from
// `test/e2e/hono_server_e2e_test.dart` (which boots the JS Hono server): the
// shape is identical — _freePort binds port 0 to discover a free port, the
// server is launched pointed at that port, readiness is polled via
// `GET /healthz`, and teardown is SIGTERM -> SIGKILL. No client is stubbed —
// the adapter tests exercise the live `dart:io` <-> shelf loopback socket.
//
// This file is a library (not `*_test.dart`), so `flutter test` does not run it
// directly; the auth/profile adapter test files import it.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A live Dart test server booted in a subprocess.
///
/// `start` binds a free port, spawns the test server on that port, and does not
/// return until `GET /healthz` answers 200 (or the readiness deadline elapses,
/// in which case it tears down and throws). `close` SIGTERMs the process and
/// force-kills it if it lingers — always best-effort and safe to call from a
/// `tearDown`.
final class TestServerHandle {
  TestServerHandle._({required this.baseUri, required this.process});

  /// Loopback base URL the booted server listens on (no trailing slash).
  final Uri baseUri;

  final Process process;

  /// Boots the test server on a free port and returns once it is healthy.
  ///
  /// [deadline] controls how long to wait for `/healthz` to answer 200; the
  /// default is generous because `dart run` runs build hooks on first boot.
  static Future<TestServerHandle> start({Duration? deadline}) async {
    final port = await freePort();
    final repoRoot = resolveRepoRoot();
    final process = await Process.start(
      'dart',
      <String>['run', 'tools/test_server/bin/server.dart', '--port', '$port'],
      workingDirectory: repoRoot,
    );

    final stdoutLines = <String>[];
    final stderrLines = <String>[];
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(stdoutLines.add);
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(stderrLines.add);

    final healthUri = Uri.parse('http://127.0.0.1:$port/healthz');
    final ready = await _waitForReady(
      process: process,
      healthUri: healthUri,
      deadline: deadline ?? const Duration(seconds: 30),
    );
    if (!ready) {
      process.kill(ProcessSignal.sigkill);
      await exitOrKill(process);
      throw StateError(
        'test_server never became ready on port $port.\n'
        'stdout:\n${stdoutLines.join('\n')}\n'
        'stderr:\n${stderrLines.join('\n')}',
      );
    }
    return TestServerHandle._(baseUri: Uri.parse('http://127.0.0.1:$port'), process: process);
  }

  Future<void> close() async {
    try {
      process.kill(); // SIGTERM is the default; escalates to SIGKILL if it lingers.
    } on Object {
      // Already gone — nothing to signal.
    }
    await exitOrKill(process);
  }
}

/// Picks a free TCP port by binding to port 0 on loopback, reading the assigned
/// port, then closing the socket. Never returns a fixed/hard-coded port.
Future<int> freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// Polls [healthUri] until it answers 200, the [process] exits, or [deadline]
/// elapses. Returns `true` only on a successful 200.
Future<bool> _waitForReady({
  required Process process,
  required Uri healthUri,
  required Duration deadline,
}) async {
  var exited = false;
  // Process.exitCode never throws, so this watcher is safe to leave unawaited.
  unawaited(process.exitCode.then((_) => exited = true));

  final end = DateTime.now().add(deadline);
  while (DateTime.now().isBefore(end)) {
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
Future<int> exitOrKill(Process process) async {
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
/// there) or — if that doesn't look like the repo — from this file's location
/// on disk.
String resolveRepoRoot() {
  final current = Directory.current;
  if (Directory(_join(current.path, 'tools', 'test_server')).existsSync()) {
    return current.path;
  }
  try {
    // test/infrastructure/test_server_handle.dart -> three `.parent`s up to root.
    final scriptFile = File(Platform.script.toFilePath());
    return scriptFile.parent.parent.parent.path;
  } on Object {
    return current.path;
  }
}

/// Joins path segments with `/` (avoids pulling in `package:path`).
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
