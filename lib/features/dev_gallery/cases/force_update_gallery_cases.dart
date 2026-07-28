import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/force_update/force_update_page.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/features/force_update/soft_update_dialog.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Builds the update-blocker gallery cases: the non-dismissible hard-block
/// [ForceUpdatePage] and the dismissible soft-deprecation [SoftUpdateCard].
///
/// Both fixtures are deterministic — no store deep-links, no snooze persistence,
/// no plugin calls. The callbacks are no-ops (C2: the gallery never fakes a
/// backend action). The soft card is rendered directly (not inside
/// [showSoftUpdateDialog]) so the preview is stable without a tap to open the
/// dialog; this mirrors the documented dual render path of [SoftUpdateCard].
List<GalleryCase> buildForceUpdateGalleryCases() {
  return [
    TypedGalleryCase<ForceUpdateState>(
      id: 'forceUpdate.hard',
      screenId: 'forceUpdate',
      screenLabelBuilder: (translations) => translations.devGallery.screenForceUpdate,
      caseLabelBuilder: (translations) => translations.devGallery.caseHardBlock,
      stateFactory: (_) => const ForceUpdateState(
        latestVersion: '2.0.0',
        storeUrl: 'https://store.example.com/app',
      ),
      pageFactory: (context, state) => ForceUpdatePage(
        state: state,
        onUpdateNow: () {},
      ),
    ),
    TypedGalleryCase<ForceUpdateState>(
      id: 'softUpdate.card',
      screenId: 'softUpdate',
      screenLabelBuilder: (translations) => translations.devGallery.screenSoftUpdate,
      caseLabelBuilder: (translations) => translations.devGallery.caseSoftUpdate,
      stateFactory: (_) => const ForceUpdateState(
        latestVersion: '1.4.0',
        storeUrl: 'https://store.example.com/app',
      ),
      pageFactory: (context, state) => _SoftUpdateCardPreview(state: state),
    ),
  ];
}

/// Centers the [SoftUpdateCard] in a constrained column so the soft-update
/// preview is stable without mounting a real dialog. The card's own layout is
/// the production surface under test; this wrapper only frames it.
class _SoftUpdateCardPreview extends StatelessWidget {
  const _SoftUpdateCardPreview({required this.state});

  final ForceUpdateState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SoftUpdateCard(state: state, onUpdate: () {}, onLater: () {}),
        ),
      ),
    );
  }
}
