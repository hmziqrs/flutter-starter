import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  test('viewport presets freeze every required boundary and review size', () {
    expect(
      GalleryViewportPresets.values.map((preset) => (preset.id, preset.size)),
      const [
        ('compact-phone', Size(390, 844)),
        ('short-phone', Size(844, 390)),
        ('below-medium', Size(639, 900)),
        ('at-medium', Size(640, 900)),
        ('medium', Size(800, 1000)),
        ('below-expanded', Size(1023, 768)),
        ('at-expanded', Size(1024, 768)),
        ('desktop', Size(1440, 900)),
        ('narrow-desktop', Size(700, 700)),
      ],
    );
    expect(
      GalleryViewportPresets.byId('at-expanded').label(AppLocale.en.buildSync()),
      'At expanded boundary',
    );
  });

  test('maximum system fixture is genuinely nonlinear', () {
    const scaler = GalleryMaximumTextScaler();

    expect(scaler.scale(10) / 10, 2);
    expect(scaler.scale(18) / 18, closeTo(1.85, 0.0001));
    expect(scaler.scale(30) / 30, 1.65);
  });

  test('environment controls update independently', () {
    final original = GalleryEnvironment.defaults();
    final updated = original.copyWith(
      highContrast: true,
      systemTextScale: GallerySystemTextScale.maximumNonlinear,
    );

    expect(updated.highContrast, isTrue);
    expect(updated.boldText, original.boldText);
    expect(updated.viewport, same(original.viewport));
    expect(updated.textScaler, isA<GalleryMaximumTextScaler>());
  });

  testWidgets('typed gallery case constructs state before the production page', (tester) async {
    late final GalleryCase galleryCase;
    await tester.pumpWidget(
      TranslationProvider(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              galleryCase = TypedGalleryCase<int>(
                id: 'test.counter.default',
                screenId: 'test.counter',
                screenLabelBuilder: (_) => 'Counter',
                caseLabelBuilder: (_) => 'Default',
                stateFactory: (_) => 7,
                pageFactory: (_, state) => Text('$state'),
              );
              return galleryCase.build(context);
            },
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(galleryCase.id, 'test.counter.default');
  });
}
