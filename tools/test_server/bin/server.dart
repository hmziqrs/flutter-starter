import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test_server/server.dart';

/// Entry point for the in-repo test server (C3).
///
/// Run:
///   dart run tools/test_server/bin/server.dart --port 8080
///   PORT=8081 dart run tools/test_server/bin/server.dart
///
/// Prints `LISTENING <port>` once bound. Defaults to port `8080`. The server is
/// a dev/test fixture only — it is never compiled into release builds.
Future<void> main(List<String> args) async {
  final port = _resolvePort(args);
  final server = await shelf_io.serve(buildHandler(), InternetAddress.loopbackIPv4, port);
  print('LISTENING ${server.port}');
}

/// Resolves the listen port from `--port` (preferred), then the `PORT` env var,
/// then [defaultPort]. Invalid values fall through to the next source.
int _resolvePort(List<String> args, {int defaultPort = 8080}) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    const flag = '--port=';
    if (arg.startsWith(flag)) {
      final parsed = int.tryParse(arg.substring(flag.length));
      if (parsed != null) return parsed;
    } else if (arg == '--port' && i + 1 < args.length) {
      final parsed = int.tryParse(args[i + 1]);
      if (parsed != null) return parsed;
    }
  }

  final envPort = Platform.environment['PORT'];
  if (envPort != null) {
    final parsed = int.tryParse(envPort);
    if (parsed != null) return parsed;
  }

  return defaultPort;
}
