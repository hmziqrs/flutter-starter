import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/settings/widgets/settings_toggle_tile.dart';
import 'package:starter/i18n/translations.g.dart';

/// Opt-in toggle for shake-to-feedback: persists `feedback.shake_enabled` via
/// [FeedbackShakeEnabledController]. The listener itself only mounts on platforms
/// with an accelerometer (gated in `app.dart` on this flag + capabilities).
class FeedbackShakeTile extends ConsumerWidget {
  const FeedbackShakeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(feedbackShakeEnabledControllerProvider.notifier);
    return SettingsToggleTile<bool>(
      watch: (ref) => ref.watch(feedbackShakeEnabledControllerProvider),
      valueSelector: (enabled) => enabled,
      onSave: (value) => controller.setEnabled(value: value),
      keyName: 'feedback-shake',
      label: Text(context.t.feedback.shakeEnabled),
    );
  }
}
