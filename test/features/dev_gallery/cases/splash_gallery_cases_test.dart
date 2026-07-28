import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/dev_gallery/cases/splash_gallery_cases.dart';
import 'package:starter/features/splash/splash_view_data.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  test('builds one deterministic case per splash phase with stable IDs', () {
    final cases = buildSplashGalleryCases();

    expect(cases, hasLength(3));
    expect(
      cases.map((galleryCase) => galleryCase.id).toList(),
      ['splash.loading', 'splash.done', 'splash.error'],
    );
    expect(cases.map((galleryCase) => galleryCase.screenId).toSet(), {'splash'});
  });

  test('every case composes the production SplashScene with a typed fixture', () {
    final translations = AppLocale.en.buildSync();
    for (final galleryCase in buildSplashGalleryCases()) {
      expect(galleryCase.screenLabel(translations), isNotEmpty);
      expect(galleryCase.caseLabel(translations), isNotEmpty);
    }
  });

  test('fixtures map back to the three SplashPhase values', () {
    final cases = buildSplashGalleryCases();
    final phases = cases.map((galleryCase) => galleryCase.id).toList();

    expect(phases, containsAll(['splash.loading', 'splash.done', 'splash.error']));
    expect(SplashFixtures.values, hasLength(3));
  });
}
