import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// SecureStore key persisting the user's analytics opt-in (C4: `SecureStore`
/// owns every secret / sensitive preference).
///
/// The stored value is the literal `'true'` when the user has opted in; absent
/// (or any other value) otherwise. This single key is shared by the real client
/// (consults it before every emit) and the feature-owned opt-in controller
/// (reads / writes it). It is intentionally NOT a `SettingsStore` key:
/// `SettingsState` fields are 1:1 with plaintext `SettingsStore` keys, and a
/// SecureStore-persisted, sensitive preference must stay off that surface.
const String analyticsOptInKey = 'analytics.opt_in';

/// Emits typed [AnalyticsEvent]s and identity updates to a measurement backend
/// (Amplitude / PostHog / Firebase GA4 / Mixpanel).
///
/// Implementations wrap their SDK in `try/on Object` and **swallow** failures:
/// analytics must never break the UX it measures. [track] is fire-and-forget on
/// the main isolate; the real impl queues to its SDK's own background uploader.
/// The contract therefore guarantees these methods never throw for backend
/// failures — a caller may `unawaited` them freely.
abstract interface class AnalyticsClient {
  /// Records [event]. Never throws for backend failures.
  Future<void> track(AnalyticsEvent event);

  /// Sets a typed [property] on the current analytics identity.
  Future<void> setUserProperty(UserProperty property);

  /// Associates ([userId]) — or dissociates (`null`) — the current identity.
  Future<void> setUserId(String? userId);
}

/// Reserved for programmer errors in [AnalyticsClient] implementations.
///
/// Never thrown for backend failures (those are swallowed per the
/// [AnalyticsClient] contract). Mirrors the per-port exception shape used by
/// `SettingsStoreException`; defined for API completeness and future strict
/// validation paths.
final class AnalyticsException implements Exception {
  const AnalyticsException({required this.operation});

  final String operation;

  @override
  String toString() => 'AnalyticsException: $operation failed';
}

/// Read-only description of where an [AnalyticsClient] sends events. Surfaced
/// on the development `DiagnosticsPage`; never drives behavior (C6).
sealed class AnalyticsClientBackend {
  const AnalyticsClientBackend();
}

/// No remote ingest is configured. Events are discarded after the local
/// application logger has recorded them for verbose dev inspection — the honest
/// no-backend default.
final class NoopAnalyticsBackend extends AnalyticsClientBackend {
  const NoopAnalyticsBackend();
}

/// Events are forwarded to a remote aggregator reachable at [host].
final class RemoteAnalyticsBackend extends AnalyticsClientBackend {
  const RemoteAnalyticsBackend({required this.host});

  final String host;
}

/// Handwritten Riverpod handle for the [AnalyticsClient] port.
///
/// Mirrors `secureStoreProvider` / `settingsRepositoryProvider`: it throws a
/// [StateError] until the composition root overrides it. The no-backend default
/// (`NoopAnalyticsClient`) is constructed in `AppDependencies.production` and
/// wired in `lib/app/app.dart` as a peer of the other port overrides. The
/// optional real impl (`PosthogAnalyticsClient`) overrides this only when the
/// consumer wires credentials AND the user has opted in (the real client
/// consults [analyticsOptInKey] before every emit). No codegen.
final analyticsClientProvider = Provider<AnalyticsClient>(
  (ref) => throw StateError('AnalyticsClient must be overridden at the composition root.'),
);

/// Read-only backend descriptor for the diagnostics page. Defaults to the
/// no-backend [NoopAnalyticsBackend]; overridden at the [ProviderScope] when a
/// remote analytics endpoint is configured. Mirrors
/// `crashReporterBackendProvider`.
final analyticsClientBackendProvider = Provider<AnalyticsClientBackend>(
  (ref) => const NoopAnalyticsBackend(),
);
