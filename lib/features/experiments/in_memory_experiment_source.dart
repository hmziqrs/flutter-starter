import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

final class InMemoryExperimentSource implements ExperimentSource {
  InMemoryExperimentSource({
    Map<ExperimentKey, ExperimentAssignment>? initial,
  }) : _current = <ExperimentKey, ExperimentAssignment>{
         ...?initial,
       },
       _controller = StreamController<List<ExperimentAssignment>>.broadcast(
         sync: true,
       );

  final Map<ExperimentKey, ExperimentAssignment> _current;
  final StreamController<List<ExperimentAssignment>> _controller;

  @visibleForTesting
  List<ExperimentAssignment> get snapshot => List<ExperimentAssignment>.unmodifiable(
    _current.values,
  );

  @override
  Future<ExperimentAssignment> assignmentFor(ExperimentKey key) async {
    final existing = _current[key];
    if (existing != null) {
      return existing;
    }
    return ExperimentAssignment(
      key: key,
      variant: const ExperimentVariantControl(),
      sticky: true,
      source: ExperimentAssignmentSource.local,
    );
  }

  @override
  Stream<List<ExperimentAssignment>> changes() => _controller.stream;

  @visibleForTesting
  void assign(
    ExperimentKey key,
    ExperimentVariant variant, {
    bool sticky = true,
    ExperimentAssignmentSource source = ExperimentAssignmentSource.local,
  }) {
    _current[key] = ExperimentAssignment(
      key: key,
      variant: variant,
      sticky: sticky,
      source: source,
    );
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
  }

  @visibleForTesting
  void dispose() {
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}
