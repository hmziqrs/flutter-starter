import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/splash/splash_page.dart';
import 'package:starter/features/splash/splash_view_data.dart';

List<GalleryCase> buildSplashGalleryCases() {
  return buildTypedGalleryCases<SplashViewData>(
    idPrefix: 'splash',
    screenId: 'splash',
    screenLabelBuilder: (t) => t.devGallery.screenSplash,
    definitions: [
      galleryCaseOf('loading', (t) => t.devGallery.caseSplashLoading, SplashFixtures.loading),
      galleryCaseOf('done', (t) => t.devGallery.caseSplashReady, SplashFixtures.done),
      galleryCaseOf('error', (t) => t.devGallery.caseSplashError, SplashFixtures.error),
    ],
    pageFactory: (context, state) => SplashScene(viewData: state),
  );
}
