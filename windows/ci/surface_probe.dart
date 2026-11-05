// A small app built on the real runner, for Desktop smoke. It stands in for the
// Dart side of docs/native_surfaces.md, so the tray scripts can check the channel
// from outside: windows/ci/drive_tray.ps1 and linux/ci/drive_tray.sh.
//
// It records what the native side says in $SURFACE_PROBE_DIR/results.jsonl, and
// publishes $SURFACE_PROBE_DIR/publish.json whenever that file appears.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _channel = MethodChannel('starter/native_surfaces');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final folder = Platform.environment['SURFACE_PROBE_DIR']!;
  final results = File('$folder/results.jsonl');

  void record(String event, Object? value) {
    results.writeAsStringSync(
      '${jsonEncode(<String, Object?>{'event': event, 'value': value})}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  _channel.setMethodCallHandler((call) async {
    if (call.method == 'openRoute') record('openRoute', call.arguments);
  });

  record('launchRoute', await _channel.invokeMethod<String>('takeLaunchRoute'));
  record('launchRouteAgain', await _channel.invokeMethod<String>('takeLaunchRoute'));
  record('startLive', await _channel.invokeMethod<bool>('startLive', '{}'));
  await _channel.invokeMethod<void>('updateLive', '{}');
  await _channel.invokeMethod<void>('endLive');
  record('liveCallsReturned', true);

  runApp(
    const ColoredBox(
      color: Color(0xFF0A0A0A),
      child: Center(
        child: Text(
          'Surface probe',
          textDirection: TextDirection.ltr,
          style: TextStyle(color: Color(0xFFFAFAFA), fontSize: 20),
        ),
      ),
    ),
  );

  final request = File('$folder/publish.json');
  var publishing = false;
  Timer.periodic(const Duration(milliseconds: 100), (_) async {
    if (publishing || !request.existsSync()) return;
    publishing = true;
    final json = await request.readAsString();
    await _channel.invokeMethod<void>('publish', json);
    await request.delete();
    record('published', json);
    publishing = false;
  });
}
