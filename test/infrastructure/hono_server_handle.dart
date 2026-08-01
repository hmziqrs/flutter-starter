import 'dart:async';
import 'dart:convert';
import 'dart:io';

final class JsRuntime {
  const JsRuntime({required this.executable, required this.prefixArgs});

  final String executable;
  final List<String> prefixArgs;

  List<String> command(String script, int port) => [
    executable,
    ...prefixArgs,
    script,
    '--port',
    '$port',
  ];

  static JsRuntime? resolve() {
    if (_probe('bun', const ['--version'])) {
      return const JsRuntime(executable: 'bun', prefixArgs: []);
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final bunPath = _join(home, '.bun', 'bin', 'bun');
      if (File(bunPath).existsSync() && _probe(bunPath, const ['--version'])) {
        return JsRuntime(executable: bunPath, prefixArgs: const []);
      }
    }
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
      return false;
    }
  }
}

final class HonoServerHandle {
  HonoServerHandle._({required this.process, required this.baseUri, required this.port});

  final Uri baseUri;

  final Process process;
  final int port;

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
      process.kill();
    } on Object {
      // ignored
    }
    await exitOrKill(process);
  }
}

Future<int> freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<bool> _waitForReady({
  required Process process,
  required Uri healthUri,
  required Duration deadline,
}) async {
  var exited = false;
  unawaited(process.exitCode.then((_) => exited = true));

  final end = DateTime.now().add(deadline);
  while (DateTime.now().isBefore(end)) {
    if (exited) return false;
    if (await _healthOk(healthUri)) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return false;
}

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

Future<int> exitOrKill(Process process) async {
  try {
    return await process.exitCode.timeout(const Duration(seconds: 5));
  } on TimeoutException {
    try {
      process.kill(ProcessSignal.sigkill);
    } on Object {
      // ignored
    }
    return process.exitCode;
  }
}

String resolveRepoRoot() {
  final current = Directory.current;
  if (Directory(_join(current.path, 'tools', 'hono_server')).existsSync()) {
    return current.path;
  }
  try {
    final scriptFile = File(Platform.script.toFilePath());
    return scriptFile.parent.parent.parent.path;
  } on Object {
    return current.path;
  }
}

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
