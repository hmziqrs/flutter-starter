import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

const String analyticsOptInKey = 'analytics.opt_in';

abstract interface class AnalyticsClient {
  Future<void> track(AnalyticsEvent event);

  Future<void> setUserProperty(UserProperty property);

  Future<void> setUserId(String? userId);
}

final class AnalyticsException implements Exception {
  const AnalyticsException({required this.operation});

  final String operation;

  @override
  String toString() => 'AnalyticsException: $operation failed';
}

sealed class AnalyticsClientBackend {
  const AnalyticsClientBackend();
}

final class NoopAnalyticsBackend extends AnalyticsClientBackend {
  const NoopAnalyticsBackend();
}

final class RemoteAnalyticsBackend extends AnalyticsClientBackend {
  const RemoteAnalyticsBackend({required this.host});

  final String host;
}

final analyticsClientProvider = Provider<AnalyticsClient>(
  (ref) => throw StateError('AnalyticsClient must be overridden at the composition root.'),
);

final analyticsClientBackendProvider = Provider<AnalyticsClientBackend>(
  (ref) => const NoopAnalyticsBackend(),
);
