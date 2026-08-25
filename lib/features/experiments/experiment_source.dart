import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/shared/state/operation_exception.dart';

part 'experiment_source.freezed.dart';

enum ExperimentAssignmentSource { local, remote }

@Freezed(toStringOverride: false)
class ExperimentAssignment with _$ExperimentAssignment {
  const ExperimentAssignment({
    required this.key,
    required this.variant,
    required this.sticky,
    required this.source,
  });

  @override
  final ExperimentKey key;

  @override
  final ExperimentVariant variant;

  @override
  final bool sticky;

  @override
  final ExperimentAssignmentSource source;

  @override
  String toString() =>
      'ExperimentAssignment(key: $key, variant: $variant, sticky: $sticky, source: $source)';
}

abstract interface class ExperimentSource {
  Future<ExperimentAssignment> assignmentFor(ExperimentKey key);

  Stream<List<ExperimentAssignment>> changes();
}

final class ExperimentSourceException extends OperationException {
  const ExperimentSourceException({required super.operation});

  @override
  String toString() => 'ExperimentSourceException: $operation failed';
}

final experimentSourceProvider = Provider<ExperimentSource>(
  (ref) => throw StateError('ExperimentSource must be overridden at the composition root.'),
);
