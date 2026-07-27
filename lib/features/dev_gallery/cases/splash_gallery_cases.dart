import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/splash/splash_page.dart';
import 'package:starter/features/splash/splash_view_data.dart';

/// Builds the in-app splash gallery cases (loading / done / error). Each case
/// composes the production [SplashScene] with a deterministic
/// [SplashViewData] fixture — no async provider, no timers, no persistence
/// (C2: the gallery never fakes a backend action). The reveal animation is
/// cosmetic and guarded inside [SplashScene]; the gallery's reduce-motion
/// toggle renders a static fallback.
List<GalleryCase> buildSplashGalleryCases() {
  return [
    TypedGalleryCase<SplashViewData>(
      id: 'splash.loading',
      screenId: 'splash',
      screenLabelBuilder: (translations) => translations.devGallery.screenSplash,
      caseLabelBuilder: (translations) => translations.devGallery.caseSplashLoading,
      stateFactory: (_) => SplashFixtures.loading,
      pageFactory: (context, state) => _SplashPreview(viewData: state),
    ),
    TypedGalleryCase<SplashViewData>(
      id: 'splash.done',
      screenId: 'splash',
      screenLabelBuilder: (translations) => translations.devGallery.screenSplash,
      caseLabelBuilder: (translations) => translations.devGallery.caseSplashReady,
      stateFactory: (_) => SplashFixtures.done,
      pageFactory: (context, state) => _SplashPreview(viewData: state),
    ),
    TypedGalleryCase<SplashViewData>(
      id: 'splash.error',
      screenId: 'splash',
      screenLabelBuilder: (translations) => translations.devGallery.screenSplash,
      caseLabelBuilder: (translations) => translations.devGallery.caseSplashError,
      stateFactory: (_) => SplashFixtures.error,
      pageFactory: (context, state) => _SplashPreview(viewData: state),
    ),
  ];
}

/// Frames the production [SplashScene] for a fixed preview state. The
/// PreviewFrame already provides the FTheme / Navigator / locale scope, so this
/// wrapper only supplies the deterministic fixture.
class _SplashPreview extends StatelessWidget {
  const _SplashPreview({required this.viewData});

  final SplashViewData viewData;

  @override
  Widget build(BuildContext context) {
    return SplashScene(viewData: viewData);
  }
}
