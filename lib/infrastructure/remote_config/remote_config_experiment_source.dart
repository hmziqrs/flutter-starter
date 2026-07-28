import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

/// Optional remote-config-backed [ExperimentSource] — the ab-experiments typed
/// port's real impl.
///
/// This adapter lives under `lib/infrastructure/remote_config/` (C4: the single
/// shared backend wrapper and its slice readers live here) and reads only the
/// `experiments` slice from the one shared [RemoteConfigClient]. It does **not**
/// own a backend connection and never opens its own `HttpClient` — that is the
/// port multiplication C4 exists to prevent. The feature-owned typed port
/// (`ExperimentSource`) and its `DeterministicExperimentSource` default live
/// with the feature under `lib/features/experiments/`.
///
/// Constructed at the composition root only when a consumer wires the backend;
/// never the default. Every backend interaction degrades to the injected
/// [fallback] (a `DeterministicExperimentSource`) on any failure — a payload
/// that cannot be fetched, parsed, or matched must never fabricate a remote
/// assignment, and must stay sticky-stable rather than throwing (the spec's
/// "remote source must degrade to the deterministic table when offline" rule).
/// Because the backend is poll-based, `changes` emits nothing; live refresh
/// flows through the controller's resume-driven `assignmentFor`.
///
/// The controller drives one `assignmentFor` per known key per refresh cycle;
/// the in-flight coalescer ([_inFlight]) collapses those concurrent calls onto
/// a single `GET /v1/remote-config` round-trip so C9's "one round-trip, one
/// cache" contract holds.
final class RemoteConfigExperimentSource implements ExperimentSource {
  /// Constructs a source that reads the `experiments` slice from a
  /// [RemoteConfigClient] configured with [baseUrl], [deviceId], and [timeout],
  /// degrading to [fallback] on any backend failure. [buildInfo] is the
  /// installed build sent as the `version` query hint.
  RemoteConfigExperimentSource({
    required Uri baseUrl,
    required AppBuildInfo buildInfo,
    required ExperimentSource fallback,
    String? deviceId,
    Duration timeout = const Duration(seconds: 5),
  }) : this.withClient(
         RemoteConfigClient(baseUrl: baseUrl, deviceId: deviceId, timeout: timeout),
         buildInfo: buildInfo,
         fallback: fallback,
       );

  /// Constructs a source backed by an explicit [client]. The default
  /// constructor redirects here; tests inject a stub client through this form.
  @visibleForTesting
  RemoteConfigExperimentSource.withClient(
    this.client, {
    required this.buildInfo,
    required this.fallback,
  });

  /// The single shared remote-config backend wrapper (C4).
  final RemoteConfigClient client;

  /// The installed build, sent as the `version` query hint.
  final AppBuildInfo buildInfo;

  /// The deterministic local table this source degrades to on any backend
  /// failure, missing entry, or malformed payload. Always a
  /// `DeterministicExperimentSource` wired by the composition root with the
  /// production `SettingsStore` so the stable device id stays consistent across
  /// the local and remote paths.
  final ExperimentSource fallback;

  /// Last successfully fetched payload, returned on a subsequent fetch failure
  /// so the source degrades to the last known good slice rather than the local
  /// table when the backend blips.
  RemoteConfigPayload? _cached;

  /// In-flight fetch future, non-null only while a fetch is running. Coalesces
  /// the concurrent `assignmentFor` calls the controller issues per refresh
  /// cycle onto a single round-trip; cleared in the `finally` so the next
  /// cycle fetches again (intended — picks up newly published assignments).
  Future<RemoteConfigPayload?>? _inFlight;

  @override
  Future<ExperimentAssignment> assignmentFor(ExperimentKey key) async {
    final payload = await _payload();
    final slice = payload?.experiments;
    if (slice == null) {
      return fallback.assignmentFor(key);
    }
    final entry = _asMap(slice[key.wireKey]);
    if (entry == null) {
      return fallback.assignmentFor(key);
    }
    final kind = ExperimentVariant.kindFromWireName(_asString(entry['variant']));
    if (kind == null) {
      return fallback.assignmentFor(key);
    }
    final variantPayload = _asMap(entry['payload']) ?? const <String, Object?>{};
    final sticky = switch (entry['sticky']) {
      final bool value => value,
      _ => true,
    };
    return ExperimentAssignment(
      key: key,
      variant: ExperimentVariant.forKind(kind, payload: variantPayload),
      sticky: sticky,
      source: ExperimentAssignmentSource.remote,
    );
  }

  @override
  Stream<List<ExperimentAssignment>> changes() => const Stream<List<ExperimentAssignment>>.empty();

  /// Fetches the payload once per refresh cycle, coalescing concurrent calls.
  /// On any failure, returns the last cached payload (or `null` if none) so
  /// [assignmentFor] degrades to the local table — never throws.
  Future<RemoteConfigPayload?> _payload() async {
    final inflight = _inFlight;
    if (inflight != null) {
      return inflight;
    }
    final completer = _PayloadCompleter();
    _inFlight = completer.future;
    try {
      final result = await client.fetch(buildInfo);
      if (result != null) {
        _cached = result;
      }
      completer.complete(result);
      return result;
    } on Object {
      // Network/parse failure: degrade to the last known good payload (or null
      // -> assignmentFor falls back to the deterministic table). Never throw.
      completer.complete(_cached);
      return _cached;
    } finally {
      _inFlight = null;
    }
  }

  static Map<String, Object?>? _asMap(Object? raw) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    return null;
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Tiny adapter exposing a `Future<RemoteConfigPayload?>` that resolves to a
/// caller-supplied value, used by the in-flight coalescer so concurrent callers
/// share one fetch result without each having to know how it was produced.
class _PayloadCompleter {
  _PayloadCompleter() : _completer = Completer<RemoteConfigPayload?>();

  final Completer<RemoteConfigPayload?> _completer;

  Future<RemoteConfigPayload?> get future => _completer.future;

  void complete(RemoteConfigPayload? value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }
}
