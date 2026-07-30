import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

/// Optional remote-config-backed [ExperimentSource]. Reads only the
/// `experiments` slice from the one shared [RemoteConfigClient] — it never
/// opens its own `HttpClient`.
///
/// Constructed at the composition root only when a consumer wires the
/// backend; never the default. Every backend interaction degrades to the
/// injected [fallback] on any failure (fetch, parse, or missing entry) rather
/// than fabricating an assignment. `changes` emits nothing since the backend
/// is poll-based; live refresh flows through the controller's resume-driven
/// `assignmentFor`.
///
/// The controller drives one `assignmentFor` per known key per refresh cycle;
/// the in-flight coalescer ([_inFlight]) collapses those onto a single
/// `GET /v1/remote-config` round-trip.
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

  /// The single shared remote-config backend wrapper.
  final RemoteConfigClient client;

  /// The installed build, sent as the `version` query hint.
  final AppBuildInfo buildInfo;

  /// The deterministic local table this source degrades to on any backend
  /// failure, missing entry, or malformed payload.
  final ExperimentSource fallback;

  /// Last successfully fetched payload, returned on a subsequent fetch
  /// failure so a backend blip degrades to the last known good slice.
  RemoteConfigPayload? _cached;

  /// In-flight fetch future; coalesces concurrent `assignmentFor` calls onto
  /// one round-trip. Cleared in `finally` so the next cycle fetches again.
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

/// Shares one fetch result across concurrent callers via the in-flight
/// coalescer.
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
