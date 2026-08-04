import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/shared/state/app_lifecycle_listener.dart';
import 'package:starter/shared/state/guarded_refresh_notifier.dart';

final featureFlagsControllerProvider = NotifierProvider<FeatureFlagsController, FeatureFlags>(
  FeatureFlagsController.new,
);

final class FeatureFlagsController extends Notifier<FeatureFlags>
    with GuardedRefreshNotifier<FeatureFlags> {
  FeatureFlagsSource get _source => ref.read(featureFlagsSourceProvider);

  @override
  AppLogger get logger => ref.read(appLoggerProvider);

  @override
  FeatureFlags build() {
    unawaited(_refresh());

    final subscription = _source.changes().listen((flags) {
      bumpLiveEpoch();
      if (state != flags) {
        state = flags;
      }
    });

    ref.onDispose(subscription.cancel);
    listenOnResume(ref, _refresh);

    return const FeatureFlags.defaults();
  }

  Future<void> _refresh() async {
    await guardedRefresh(
      load: _source.load,
      apply: (flags) {
        if (state != flags) {
          state = flags;
        }
      },
      errorMessage: 'Feature flag refresh failed',
    );
  }

  bool isEnabled(FeatureFlag flag) => state.isEnabled(flag);
}
