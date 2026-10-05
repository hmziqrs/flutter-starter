import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/error_reporting/http_crash_reporter.dart';

void main() {
  late _RecordingAdapter adapter;

  HttpCrashReporter reporter({required bool verbose}) => HttpCrashReporter(
    baseUrl: Uri.parse('https://backend.example.test'),
    platform: 'macos',
    appVersion: '1.2.3+42',
    verbose: verbose,
    dio: Dio(BaseOptions(baseUrl: 'https://backend.example.test'))..httpClientAdapter = adapter,
  );

  setUp(() => adapter = _RecordingAdapter());

  Map<String, Object?> bodyAt(int index) =>
      jsonDecode(adapter.requests[index].body) as Map<String, Object?>;

  test('POSTs the contract payload to /v1/crashes, gating the stack on verbose', () async {
    await reporter(verbose: true).recordError(
      StateError('boom'),
      StackTrace.current,
      context: const <String, Object?>{'source': 'platform'},
    );
    await reporter(verbose: false).recordError(StateError('boom'), StackTrace.current);

    final request = adapter.requests.first;
    expect(request.options.uri.path, '/v1/crashes');
    expect(bodyAt(0)['message'], contains('boom'));
    expect(bodyAt(0)['stack'], isA<String>());
    expect(bodyAt(0)['context'], <String, Object?>{'source': 'platform'});
    expect(bodyAt(0)['platform'], 'macos');
    expect(bodyAt(0)['appVersion'], '1.2.3+42');
    expect(bodyAt(1).containsKey('stack'), isFalse);
  });

  test('never rethrows: transport failures and error statuses are dropped', () async {
    await reporter(verbose: false).recordError(StateError('boom'), StackTrace.current);
    adapter
      ..failure = StateError('network down')
      ..statusToReturn = 500;
    await expectLater(
      reporter(verbose: false).recordError(StateError('boom'), StackTrace.current),
      completes,
    );
    expect(adapter.requests, hasLength(2));
  });

  test('a self-built transport times out a hung backend and drops the report', () async {
    // Accepts the request but never answers, so only the reporter's own
    // receive-timeout can end the POST; an untimed transport would hang here.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) {});

    final slow = HttpCrashReporter(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      platform: 'macos',
      appVersion: '1.2.3+42',
      verbose: false,
      timeout: const Duration(milliseconds: 25),
    );

    await slow
        .recordError(StateError('hung backend'), StackTrace.current)
        .timeout(const Duration(seconds: 5));
  });
}

final class _RecordingAdapter implements HttpClientAdapter {
  final List<({RequestOptions options, String body})> requests = [];
  int statusToReturn = 204;
  Error? failure;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = await (requestStream ?? const Stream<Uint8List>.empty()).toList();
    requests.add((options: options, body: utf8.decode(bytes.expand((c) => c).toList())));
    final thrown = failure;
    if (thrown != null) {
      throw thrown;
    }
    return ResponseBody.fromString('', statusToReturn);
  }

  @override
  void close({bool force = false}) {}
}
