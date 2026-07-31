import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';

final class InMemoryFeatureFlagsSource implements FeatureFlagsSource {
  InMemoryFeatureFlagsSource({FeatureFlags? initial})
    : _current = initial ?? const FeatureFlags.defaults(),
      _controller = StreamController<FeatureFlags>.broadcast(sync: true);

  FeatureFlags _current;
  final StreamController<FeatureFlags> _controller;

  @visibleForTesting
  FeatureFlags get current => _current;

  @override
  Future<FeatureFlags> load() async => _current;

  @override
  Stream<FeatureFlags> changes() => _controller.stream;

  @visibleForTesting
  void emit(FeatureFlags flags) {
    _current = flags;
    if (!_controller.isClosed) {
      _controller.add(flags);
    }
  }

  @visibleForTesting
  void dispose() {
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}
