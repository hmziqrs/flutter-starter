import 'dart:async';

import 'package:dio/dio.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// [AnalyticsClient] that buffers events and POSTs them in contract-C3 batches
/// (`{events: [{type, name, props, ts}], userId?}`) to `POST /v1/events`.
/// Constructed in `AppDependencies.production` only when `AppConfig` carries a
/// `backendBaseUrl`, behind the opt-in gate (`OptInGatedAnalyticsClient`);
/// never throws — a failed batch is dropped, not retried.
///
/// Buffered events upload on whichever trigger comes first: the [batchSize]
/// threshold or a [flushInterval] tick of the periodic flush ticker, so a
/// low-traffic session still uploads without waiting for a full batch.
final class HttpAnalyticsClient implements AnalyticsClient {
  HttpAnalyticsClient({
    required Uri baseUrl,
    Dio? dio,
    this.batchSize = 20,
    this.flushInterval = defaultFlushInterval,
    Stream<void> Function(Duration interval)? flushTicker,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl.toString(),
               validateStatus: (_) => true,
               connectTimeout: _timeout,
               sendTimeout: _timeout,
               receiveTimeout: _timeout,
             ),
           ) {
    if (flushInterval > Duration.zero) {
      _flushSubscription = (flushTicker ?? _periodicTicker)(
        flushInterval,
      ).listen((_) => _onFlushTick());
    }
  }

  static const Duration _timeout = Duration(seconds: 10);

  /// Bounded time between background flushes (see the class doc).
  static const Duration defaultFlushInterval = Duration(seconds: 20);

  final int batchSize;
  final Duration flushInterval;
  final Dio _dio;
  final List<Map<String, Object?>> _pending = <Map<String, Object?>>[];
  String? _userId;
  StreamSubscription<void>? _flushSubscription;

  static Stream<void> _periodicTicker(Duration interval) => Stream<void>.periodic(interval);

  /// POSTs every buffered event now (also fires automatically at [batchSize]
  /// and on each [flushInterval] tick).
  Future<void> flush() async {
    if (_pending.isEmpty) {
      return;
    }
    final events = List<Map<String, Object?>>.of(_pending);
    _pending.clear();
    try {
      await _dio.post<Object?>(
        '/v1/events',
        data: <String, Object?>{'events': events, 'userId': ?_userId},
      );
    } on Object {}
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    _pending.add(_encode(event));
    if (_pending.length >= batchSize) {
      await flush();
    }
  }

  /// Cancels the periodic flush ticker. The client is constructed once per app
  /// process, so production never needs this; tests that inject a ticker (or
  /// pump the wired app) call it to drop the pending tick. Events still
  /// buffered at dispose are dropped, matching the never-retry contract.
  void dispose() {
    unawaited(_flushSubscription?.cancel());
    _flushSubscription = null;
  }

  void _onFlushTick() {
    if (_pending.isEmpty) {
      return;
    }
    unawaited(flush());
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    // The /v1/events contract has no user-property surface; identity flows via
    // the batch-level `userId` only (plans/feature_roadmap/features/analytics.md).
  }

  @override
  Future<void> setUserId(String? userId) async {
    await flush(); // Buffered events keep the identity they were captured with.
    _userId = userId;
  }

  Map<String, Object?> _encode(AnalyticsEvent event) {
    final ts = DateTime.now().toUtc().toIso8601String();
    return switch (event) {
      ScreenView(:final routeName) => {
        'type': 'screen_view',
        'name': routeName,
        'props': const <String, Object?>{},
        'ts': ts,
      },
      Tap(:final target) => {
        'type': 'tap',
        'name': target,
        'props': const <String, Object?>{},
        'ts': ts,
      },
      FunnelStep(:final name, :final step) => {
        'type': 'funnel_step',
        'name': name,
        'props': <String, Object?>{'step': step},
        'ts': ts,
      },
    };
  }
}
