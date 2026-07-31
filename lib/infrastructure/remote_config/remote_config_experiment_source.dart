import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

final class RemoteConfigExperimentSource implements ExperimentSource {
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

  @visibleForTesting
  RemoteConfigExperimentSource.withClient(
    this.client, {
    required this.buildInfo,
    required this.fallback,
  });

  final RemoteConfigClient client;

  final AppBuildInfo buildInfo;

  final ExperimentSource fallback;

  RemoteConfigPayload? _cached;

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
