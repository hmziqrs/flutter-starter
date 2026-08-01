import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';

final featureFlagsControllerProvider = NotifierProvider<FeatureFlagsController, FeatureFlags>(
  FeatureFlagsController.new,
);

final class FeatureFlagsController extends Notifier<FeatureFlags> {
  FeatureFlagsSource get _source => ref.read(featureFlagsSourceProvider);

  int _liveEpoch = 0;

  @override
  FeatureFlags build() {
    unawaited(_refresh());

    final subscription = _source.changes().listen((flags) {
      _liveEpoch++;
      if (state != flags) {
        state = flags;
      }
    });

    ref
      ..onDispose(subscription.cancel)
      ..listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
        final wasResumed = previous?.isResumed ?? false;
        if (next.isResumed && !wasResumed) {
          unawaited(_refresh());
        }
      });

    return const FeatureFlags.defaults();
  }

  Future<void> _refresh() async {
    final epochAtStart = _liveEpoch;
    try {
      final flags = await _source.load();
      if (epochAtStart == _liveEpoch && state != flags) {
        state = flags;
      }
    } on Object {
      // ignored
    }
  }

  bool isEnabled(FeatureFlag flag) => state.isEnabled(flag);
}
