import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';

/// Deterministic `FeatureFlagsSource` for the no-backend production default,
/// unit tests, and the dev-gallery.
///
/// Dual-purpose, mirroring the peer `InMemoryVersionGateStore` (not a test-only
/// fake like `InMemorySecureStore`): constructed in `AppDependencies.production`
/// seeded with `FeatureFlags.defaults` so the app runs green with zero backend wiring
/// and never emits a change (the honest no-backend baseline — C2). Tests and
/// dev-gallery fixtures seed an alternate value and drive [emit] to exercise the
/// controller's live-update path deterministically.
final class InMemoryFeatureFlagsSource implements FeatureFlagsSource {
  InMemoryFeatureFlagsSource({FeatureFlags? initial})
    : _current = initial ?? const FeatureFlags.defaults(),
      _controller = StreamController<FeatureFlags>.broadcast(sync: true);

  FeatureFlags _current;
  final StreamController<FeatureFlags> _controller;

  /// The flags this source currently reports. Read-only test/diagnostics handle.
  @visibleForTesting
  FeatureFlags get current => _current;

  @override
  Future<FeatureFlags> load() async => _current;

  @override
  Stream<FeatureFlags> changes() => _controller.stream;

  /// Replaces the current flags and emits on [changes] (tests / dev-gallery
  /// only). The production no-backend default is constructed once and never
  /// calls this, so it emits nothing.
  @visibleForTesting
  void emit(FeatureFlags flags) {
    _current = flags;
    if (!_controller.isClosed) {
      _controller.add(flags);
    }
  }

  /// Closes the backing `StreamController`. Tests call this in `tearDown`.
  @visibleForTesting
  void dispose() {
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}
