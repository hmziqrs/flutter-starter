import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';

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
