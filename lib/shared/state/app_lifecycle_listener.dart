import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';

/// Registers [callback] to fire only on the resume edge of the app lifecycle.
///
/// The first transition into a resumed phase (where the previous phase was not
/// resumed) triggers [callback]; subsequent resumed-to-resumed transitions and
/// all other phases are ignored. This mirrors the common "refresh on resume"
/// pattern used by controllers that re-load state when the app returns to the
/// foreground.
void listenOnResume(Ref ref, Future<void> Function() callback) {
  ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
    final wasResumed = previous?.isResumed ?? false;
    if (next.isResumed && !wasResumed) {
      unawaited(callback());
    }
  });
}
