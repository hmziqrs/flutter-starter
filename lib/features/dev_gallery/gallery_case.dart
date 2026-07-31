import 'package:flutter/widgets.dart';
import 'package:starter/app/presentation/production_page_factory.dart';
import 'package:starter/i18n/translations.g.dart';

typedef GalleryLabelBuilder = String Function(Translations translations);
typedef GalleryStateFactory<TState> = TState Function(BuildContext context);

abstract interface class GalleryCase {
  String get id;
  String get screenId;
  String screenLabel(Translations translations);
  String caseLabel(Translations translations);
  Widget build(BuildContext context);
}

final class TypedGalleryCase<TState> implements GalleryCase {
  const TypedGalleryCase({
    required this.id,
    required this.screenId,
    required this.screenLabelBuilder,
    required this.caseLabelBuilder,
    required this.stateFactory,
    required this.pageFactory,
  });

  @override
  final String id;

  @override
  final String screenId;

  final GalleryLabelBuilder screenLabelBuilder;
  final GalleryLabelBuilder caseLabelBuilder;
  final GalleryStateFactory<TState> stateFactory;
  final ProductionPageFactory<TState> pageFactory;

  @override
  String screenLabel(Translations translations) => screenLabelBuilder(translations);

  @override
  String caseLabel(Translations translations) => caseLabelBuilder(translations);

  @override
  Widget build(BuildContext context) {
    return pageFactory(context, stateFactory(context));
  }
}

typedef GalleryCaseDefinition<TState> = ({
  String suffix,
  GalleryLabelBuilder labelBuilder,
  GalleryStateFactory<TState> stateFactory,
});

GalleryCaseDefinition<TState> galleryCaseOf<TState>(
  String suffix,
  GalleryLabelBuilder labelBuilder,
  TState state,
) => (suffix: suffix, labelBuilder: labelBuilder, stateFactory: (_) => state);

List<GalleryCase> buildTypedGalleryCases<TState>({
  required String idPrefix,
  required String screenId,
  required GalleryLabelBuilder screenLabelBuilder,
  required List<GalleryCaseDefinition<TState>> definitions,
  required ProductionPageFactory<TState> pageFactory,
}) {
  return [
    for (final definition in definitions)
      TypedGalleryCase<TState>(
        id: '$idPrefix.${definition.suffix}',
        screenId: screenId,
        screenLabelBuilder: screenLabelBuilder,
        caseLabelBuilder: definition.labelBuilder,
        stateFactory: definition.stateFactory,
        pageFactory: pageFactory,
      ),
  ];
}
