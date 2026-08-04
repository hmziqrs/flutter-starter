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

/// Builds one [TypedGalleryCase] per entry in [values].
///
/// Each case is assembled from the value's `name` (suffixed onto
/// [idPrefix]), the shared [screenLabelBuilder], the per-value
/// [caseLabelBuilder], and the shared [pageFactory]. This absorbs the
/// `for (final value in E.values)` + `TypedGalleryCase` boilerplate that
/// otherwise repeats across enum-driven gallery case files. Callers pass the
/// concrete enum's `values` list because Dart cannot reach it through the
/// generic type parameter.
List<GalleryCase> buildEnumGalleryCases<T extends Enum>({
  required Iterable<T> values,
  required String idPrefix,
  required String screenId,
  required GalleryLabelBuilder screenLabelBuilder,
  required GalleryLabelBuilder Function(T value) caseLabelBuilder,
  required ProductionPageFactory<T> pageFactory,
}) {
  return [
    for (final value in values)
      TypedGalleryCase<T>(
        id: '$idPrefix.${value.name}',
        screenId: screenId,
        screenLabelBuilder: screenLabelBuilder,
        caseLabelBuilder: caseLabelBuilder(value),
        stateFactory: (_) => value,
        pageFactory: pageFactory,
      ),
  ];
}
