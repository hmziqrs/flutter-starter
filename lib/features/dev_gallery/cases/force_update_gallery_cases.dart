import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/force_update/force_update_page.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/features/force_update/soft_update_dialog.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

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
