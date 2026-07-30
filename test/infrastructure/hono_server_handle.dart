// Shared harness that boots the REAL in-repo Hono server
// (`tools/hono_server`) on a free port as a subprocess, for live-server tests.
// A JS runtime (bun preferred, else `npx tsx`) must be reachable; otherwise
// [JsRuntime.resolve] returns null and callers should skip (not fail) — the repo
// documents bun as the runtime, and CI installs it.
//
// `start` binds a free port, spawns the runtime pointed at the server script,
// and does not return until `GET /healthz` answers 200 (or the readiness
// deadline elapses, in which case it tears down and throws). `close` SIGTERMs
// the process and force-kills it if it lingers — always best-effort and safe to
// call from a `tearDown`.
//
// This file is a library (not `*_test.dart`), so `flutter test` does not run it
// directly; live-server test files import it.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Resolved JS runtime command for booting the Hono server.
///
/// `executable` is what `Process.start` invokes; `prefixArgs` is the argv that
/// precedes the server script path (`const []` for bun, `const ['tsx']` for the
/// `npx tsx` fallback).
final class JsRuntime {
  const JsRuntime({required this.executable, required this.prefixArgs});

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
  static JsRuntime? resolve() {
    // 1. bun somewhere on PATH.
    if (_probe('bun', const ['--version'])) {
      return const JsRuntime(executable: 'bun', prefixArgs: []);
    }
    // 2. bun installed at its well-known location but not on PATH (common when
    //    `flutter test` is launched with a sanitized environment).
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final bunPath = _join(home, '.bun', 'bin', 'bun');
      if (File(bunPath).existsSync() && _probe(bunPath, const ['--version'])) {
        return JsRuntime(executable: bunPath, prefixArgs: const []);
      }
    }
    // 3. Node via npx tsx (downloads tsx on demand).
    if (_probe('npx', const ['--version'])) {
      return const JsRuntime(executable: 'npx', prefixArgs: ['tsx']);
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
final class HonoServerHandle {
  HonoServerHandle._({required this.process, required this.baseUri, required this.port});

  /// Loopback base URL the booted server listens on (no trailing slash).
  final Uri baseUri;

  final Process process;
  final int port;

  /// Boots the Hono server on a free port and returns once it is healthy.
  ///
  /// [runtime] defaults to [JsRuntime.resolve]; when that is `null` (no JS
  /// runtime reachable) this throws a [StateError] — callers should resolve
  /// first and skip instead of calling [start] in that case. [deadline]
  /// controls how long to wait for `/healthz` to answer 200.
  static Future<HonoServerHandle> start({JsRuntime? runtime, Duration? deadline}) async {
    final js = runtime ?? JsRuntime.resolve();
    if (js == null) {
      throw StateError('No JS runtime (bun or npx tsx) available to boot the Hono server.');
    }
    final repoRoot = resolveRepoRoot();
    final script = _join(repoRoot, 'tools', 'hono_server', 'src', 'index.ts');
    final port = await freePort();
    final argv = js.command(script, port);
    final process = await Process.start(
      argv.first,
      argv.skip(1).toList(),
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
      // Best-effort cleanup before surfacing the failure.
      process.kill(ProcessSignal.sigkill);
      await exitOrKill(process);
      throw StateError(
        'Hono server never became ready on port $port (ran: ${argv.join(' ')}).\n'
        'stdout:\n${stdoutLines.join('\n')}\n'
        'stderr:\n${stderrLines.join('\n')}',
      );
    }
    return HonoServerHandle._(
      process: process,
      baseUri: Uri.parse('http://127.0.0.1:$port'),
      port: port,
    );
  }

  Future<void> close() async {
    try {
      process.kill(); // SIGTERM is the default; escalates to SIGKILL below if it lingers.
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
  if (Directory(_join(current.path, 'tools', 'hono_server')).existsSync()) {
    return current.path;
  }
  try {
    // test/infrastructure/hono_server_handle.dart -> three `.parent`s up to root.
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
