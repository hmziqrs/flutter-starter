import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';

void listenOnResume(Ref ref, Future<void> Function() callback) {
  ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
    final wasResumed = previous?.isResumed ?? false;
    if (next.isResumed && !wasResumed) {
      unawaited(callback());
    }
  });
}
