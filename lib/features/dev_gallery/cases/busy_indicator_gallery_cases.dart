import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

/// Immutable, deterministic preview state for the busy-indicator gallery cases.
/// One variant per previewed surface; no timers, no animated state, no async
/// work (C2: the gallery never fakes a backend action).
enum BusyGalleryState {
  /// Indeterminate progress (`value` is `null`).
  indeterminate(asOverlay: false),

  /// Determinate progress at 0.6.
  determinate(value: 0.6, asOverlay: false),

  /// Modal overlay variant.
  overlay(value: 0.6, asOverlay: true);

  const BusyGalleryState({required this.asOverlay, this.value});

  /// Determinate progress fraction (`null` is indeterminate).
  final double? value;

  /// When true, the case mounts the modal [BusyOverlay]; otherwise the bare
  /// [BusyIndicator] is centered.
  final bool asOverlay;
}

/// Builds the busy-indicator gallery cases: an indeterminate [BusyIndicator], a
/// determinate [BusyIndicator] at 0.6, and a modal [BusyOverlay] scrim. Every
/// case is a static fixture — the overlay's [BusyOverlay.isBusy] is pinned true
/// so the scrim is always visible in the gallery.
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

/// Centers a bare [BusyIndicator] — the production primitive under test —
/// against the gallery placeholder body. No callbacks, no side effects.
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

/// Mounts [BusyOverlay] over a static placeholder with [BusyOverlay.isBusy]
/// pinned true, so the modal scrim and indicator are always visible. The
/// underlying content stays non-interactive (the overlay absorbs pointers) but
/// the gallery never wires a real submit.
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
