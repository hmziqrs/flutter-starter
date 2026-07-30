import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

enum BusyGalleryState { indeterminate, determinate, overlay }

/// Builds the busy-indicator gallery cases: an indeterminate [BusyIndicator], a
/// determinate [BusyIndicator] at 0.6, and a modal [BusyOverlay] scrim, pinned
/// with [BusyOverlay.isBusy] always true so the scrim stays visible.
List<GalleryCase> buildBusyIndicatorGalleryCases() {
  return [
    TypedGalleryCase<BusyGalleryState>(
      id: 'busy.indeterminate',
      screenId: 'busy',
      screenLabelBuilder: (translations) => translations.devGallery.screenBusy,
      caseLabelBuilder: (translations) => translations.devGallery.caseBusyIndeterminate,
      stateFactory: (_) => BusyGalleryState.indeterminate,
      pageFactory: (context, state) => const _BusyIndicatorPreview(value: null),
    ),
    TypedGalleryCase<BusyGalleryState>(
      id: 'busy.determinate',
      screenId: 'busy',
      screenLabelBuilder: (translations) => translations.devGallery.screenBusy,
      caseLabelBuilder: (translations) => translations.devGallery.caseBusyDeterminate,
      stateFactory: (_) => BusyGalleryState.determinate,
      pageFactory: (context, state) => const _BusyIndicatorPreview(value: 0.6),
    ),
    TypedGalleryCase<BusyGalleryState>(
      id: 'busy.overlay',
      screenId: 'busy',
      screenLabelBuilder: (translations) => translations.devGallery.screenBusy,
      caseLabelBuilder: (translations) => translations.devGallery.caseBusyOverlay,
      stateFactory: (_) => BusyGalleryState.overlay,
      pageFactory: (context, state) => const _BusyOverlayPreview(),
    ),
  ];
}

class _BusyIndicatorPreview extends StatelessWidget {
  const _BusyIndicatorPreview({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: BusyIndicator(value: value),
      ),
    );
  }
}

class _BusyOverlayPreview extends StatelessWidget {
  const _BusyOverlayPreview();

  @override
  Widget build(BuildContext context) {
    return BusyOverlay(
      isBusy: true,
      value: 0.6,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(context.t.devGallery.preview),
      ),
    );
  }
}
