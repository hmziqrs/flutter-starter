import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

/// Where an [ExperimentAssignment] was resolved.
///
/// - [local]: the deterministic local table bucketed it (the no-backend
///   default, or the offline degrade of the remote source).
/// - [remote]: the optional remote-config reader resolved it from the
///   `experiments` slice of the shared backend response.
///
/// Surfaced on the diagnostics snapshot so a developer can see at a glance
/// whether a given assignment is the honest local fallback or a real remote
/// resolution.
enum ExperimentAssignmentSource { local, remote }

/// A single resolved `(key, variant, sticky, source)` tuple.
///
/// `sticky` is `true` when the assignment is stable for the stable device id
/// across launches (always `true` for the deterministic local source; carried
/// from the backend `sticky` field for the remote source). Value equality over
/// every field so the controller's snapshot diff detects real changes only.
@immutable
final class ExperimentAssignment {
  /// Constructs an assignment.
  const ExperimentAssignment({
    required this.key,
    required this.variant,
    required this.sticky,
    required this.source,
  });

  /// The experiment this assignment resolves.
  final ExperimentKey key;

  /// The resolved variant (and its payload).
  final ExperimentVariant variant;

  /// Whether the assignment is stable across launches for this device.
  final bool sticky;

  /// Whether the assignment came from the local table or the remote backend.
  final ExperimentAssignmentSource source;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExperimentAssignment &&
            key == other.key &&
            variant == other.variant &&
            sticky == other.sticky &&
            source == other.source;
  }

  @override
  int get hashCode => Object.hash(key, variant, sticky, source);

  @override
  String toString() =>
      'ExperimentAssignment(key: $key, variant: $variant, sticky: $sticky, source: $source)';
}

/// Typed source of experiment assignments — the ab-experiments reader on the
/// shared remote-config family (C4).
///
/// The port lives **with its feature** (`lib/features/experiments/`, mirroring
/// the `SettingsStore` / `FeatureFlagsSource` exemplars); only the optional
/// production adapter that reads a remote-config backend lives under
/// `lib/infrastructure/remote_config/`. It is one of three peer typed ports —
/// alongside `FeatureFlagsSource` (feature-flags) and `VersionGateStore`
/// (update-blocker) — that each own their own default and read a distinct slice
/// from the single shared backend wrapper. No reader opens its own backend
/// connection.
///
/// Implementations wrap their backing source in `try/on Object` and degrade to
/// the deterministic local table on any backend failure: a source that cannot
/// be read must never fabricate a remote assignment (C2). The deterministic
/// default is a **real** local assignment (stable, reproducible, no network),
/// not a Noop — see `DeterministicExperimentSource`.
abstract interface class ExperimentSource {
  /// Returns the resolved [ExperimentAssignment] for [key]. Never throws for
  /// backend failures — the remote reader degrades to the deterministic local
  /// table instead, and the deterministic source is always local.
  Future<ExperimentAssignment> assignmentFor(ExperimentKey key);

  /// Live updates to the full assignment snapshot, for sources that can push
  /// (the in-memory fake in tests). Poll-backed sources (the deterministic
  /// default, the optional remote reader) emit nothing here and refresh through
  /// [assignmentFor] on the controller's resume-driven refresh.
  Stream<List<ExperimentAssignment>> changes();
}

/// Thrown by [ExperimentSource] implementations only for programmer errors
/// (never for backend failures, which degrade to the deterministic table).
/// Mirrors the peer `FeatureFlagsException` / `VersionGateException`.
final class ExperimentSourceException implements Exception {
  /// Constructs an exception describing the failing [operation].
  const ExperimentSourceException({required this.operation});

  /// The operation that failed (e.g. `'assignmentFor'`).
  final String operation;

  @override
  String toString() => 'ExperimentSourceException: $operation failed';
}

/// Handwritten Riverpod handle for the [ExperimentSource] port.
///
/// Mirrors `settingsStoreProvider` / `featureFlagsSourceProvider` /
/// `versionGateStoreProvider`: it throws a [StateError] until the composition
/// root overrides it with a concrete adapter. The no-backend default
/// (`DeterministicExperimentSource` — a real local assignment, not a Noop) is
/// constructed in `AppDependencies.production` and wired in `lib/app/app.dart`
/// as a peer of the other port overrides. No codegen.
final experimentSourceProvider = Provider<ExperimentSource>(
  (ref) => throw StateError('ExperimentSource must be overridden at the composition root.'),
);
