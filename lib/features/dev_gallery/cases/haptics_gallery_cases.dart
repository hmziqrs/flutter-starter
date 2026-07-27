import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Builds the haptics dev-gallery case: a single "Haptics" screen whose preview
/// is a button row that triggers each [HapticKind].
///
/// The preview inherits `hapticServiceProvider` from the surrounding app scope
/// rather than nesting its own override: the production app supplies
/// `DeviceHapticService` (so a dev feels the buzz), while the inMemory test/golden
/// harness supplies `NoopHapticService` (so a tap never reaches the platform
/// channel during capture). The canonical call-site gating contract runs here
/// verbatim — fire only when the user opt-in
/// (`settingsControllerProvider.hapticsEnabled`) is on AND reduce-motion
/// (`MediaQuery.disableAnimationsOf`) is off. This is the single load-bearing
/// guardrail for the feature (see the haptics spec audit); it lives at the call
/// site, not inside the port, so every consumer stays auditable.
List<GalleryCase> buildHapticsGalleryCases() {
  return [
    TypedGalleryCase<List<HapticKind>>(
      id: 'haptics.kinds',
      screenId: 'haptics',
      screenLabelBuilder: (translations) => translations.devGallery.screenHaptics,
      caseLabelBuilder: (translations) => translations.devGallery.caseHapticKinds,
      stateFactory: (_) => HapticKind.values,
      pageFactory: (context, state) => _HapticsPreview(kinds: state),
    ),
  ];
}

class _HapticsPreview extends ConsumerWidget {
  const _HapticsPreview({required this.kinds});

  final List<HapticKind> kinds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < kinds.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            FButton(
              key: ValueKey('haptics-trigger-${kinds[index].name}'),
              variant: .outline,
              onPress: () => _trigger(context, ref, kinds[index]),
              child: Text(_hapticKindLabel(translations, kinds[index])),
            ),
          ],
        ],
      ),
    );
  }

  /// Canonical call-site gating contract: fire only when the user opt-in is on
  /// and reduce-motion is off. Haptics are fire-and-forget — any platform error
  /// is swallowed via `Future.ignore` so a failed buzz never gates a user
  /// action. With the inMemory `NoopHapticService` override nothing fires on
  /// the device; the gate runs regardless to keep the contract auditable.
  void _trigger(BuildContext context, WidgetRef ref, HapticKind kind) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    if (!ref.read(settingsControllerProvider).hapticsEnabled) {
      return;
    }
    ref.read(hapticServiceProvider).trigger(kind).ignore();
  }
}

String _hapticKindLabel(Translations translations, HapticKind kind) {
  return switch (kind) {
    HapticKind.selection => translations.devGallery.caseHapticSelection,
    HapticKind.impactLight => translations.devGallery.caseHapticImpactLight,
    HapticKind.impactMedium => translations.devGallery.caseHapticImpactMedium,
    HapticKind.impactHeavy => translations.devGallery.caseHapticImpactHeavy,
    HapticKind.notificationSuccess => translations.devGallery.caseHapticSuccess,
    HapticKind.notificationWarning => translations.devGallery.caseHapticWarning,
    HapticKind.notificationError => translations.devGallery.caseHapticError,
  };
}
