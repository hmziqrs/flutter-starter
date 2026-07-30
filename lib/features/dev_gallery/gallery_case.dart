import 'package:flutter/widgets.dart';
import 'package:starter/app/presentation/production_page_factory.dart';
import 'package:starter/i18n/translations.g.dart';

typedef GalleryLabelBuilder = String Function(Translations translations);
typedef GalleryStateFactory<TState> = TState Function(BuildContext context);

/// A type-erased gallery entry that still constructs a typed production state.
abstract interface class GalleryCase {
  String get id;
  String get screenId;
  String screenLabel(Translations translations);
  String caseLabel(Translations translations);
  Widget build(BuildContext context);
}

/// Adapts one immutable presentation state to a real production-page factory.
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

/// One case's id suffix, label, and state, sharing a screen and page factory
/// supplied by [buildTypedGalleryCases].
typedef GalleryCaseDefinition<TState> = ({
  String suffix,
  GalleryLabelBuilder labelBuilder,
  GalleryStateFactory<TState> stateFactory,
});

/// Shorthand for a [GalleryCaseDefinition] with a fixed, already-built state.
GalleryCaseDefinition<TState> galleryCaseOf<TState>(
  String suffix,
  GalleryLabelBuilder labelBuilder,
  TState state,
) => (suffix: suffix, labelBuilder: labelBuilder, stateFactory: (_) => state);

/// Expands a list of [GalleryCaseDefinition]s sharing one screen and page
/// factory into their [TypedGalleryCase]s.
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
