import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// SecureStore key persisting the user's analytics opt-in. Value is the
/// literal `'true'` when opted in; absent (or anything else) otherwise.
/// Shared by the real client (consults it before every emit) and the
/// feature-owned opt-in controller. Deliberately not a `SettingsStore` key —
/// a sensitive preference stays off that plaintext surface.
const String analyticsOptInKey = 'analytics.opt_in';

/// Emits typed [AnalyticsEvent]s and identity updates to a measurement
/// backend (Amplitude / PostHog / Firebase GA4 / Mixpanel).
///
/// Implementations wrap their SDK in `try/on Object` and swallow failures —
/// analytics must never break the UX it measures, so a caller may `unawaited`
/// these freely.
abstract interface class AnalyticsClient {
  /// Records [event]. Never throws for backend failures.
  Future<void> track(AnalyticsEvent event);

  /// Sets a typed [property] on the current analytics identity.
  Future<void> setUserProperty(UserProperty property);

  /// Associates ([userId]) — or dissociates (`null`) — the current identity.
  Future<void> setUserId(String? userId);
}

/// Reserved for programmer errors in [AnalyticsClient] implementations
/// (backend failures are swallowed, never thrown here).
final class AnalyticsException implements Exception {
  const AnalyticsException({required this.operation});

  final String operation;

  @override
  String toString() => 'AnalyticsException: $operation failed';
}

/// Read-only description of where an [AnalyticsClient] sends events. Surfaced
/// on the development `DiagnosticsPage`; never drives behavior.
sealed class AnalyticsClientBackend {
  const AnalyticsClientBackend();
}

/// No remote ingest is configured. Events are discarded after the local
/// application logger has recorded them for verbose dev inspection.
final class NoopAnalyticsBackend extends AnalyticsClientBackend {
  const NoopAnalyticsBackend();
}

/// Events are forwarded to a remote aggregator reachable at [host].
final class RemoteAnalyticsBackend extends AnalyticsClientBackend {
  const RemoteAnalyticsBackend({required this.host});

  final String host;
}

/// Throws a [StateError] until the composition root overrides it. The
/// no-backend default (`NoopAnalyticsClient`) is constructed in
/// `AppDependencies.production`; the optional real impl
/// (`PosthogAnalyticsClient`) is used only when credentials are wired and the
/// user has opted in.
final analyticsClientProvider = Provider<AnalyticsClient>(
  (ref) => throw StateError('AnalyticsClient must be overridden at the composition root.'),
);

/// Read-only backend descriptor for the diagnostics page. Defaults to the
/// no-backend [NoopAnalyticsBackend]; overridden when a remote analytics
/// endpoint is configured.
final analyticsClientBackendProvider = Provider<AnalyticsClientBackend>(
  (ref) => const NoopAnalyticsBackend(),
);
