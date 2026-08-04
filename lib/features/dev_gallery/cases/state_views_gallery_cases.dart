import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';
import 'package:starter/shared/widgets/states/error_state_view.dart';
import 'package:starter/shared/widgets/states/loading_state_view.dart';

enum StateViewsGalleryState { empty, error, loading }

List<GalleryCase> buildStateViewsGalleryCases() {
  return <GalleryCase>[
    TypedGalleryCase<StateViewsGalleryState>(
      id: 'stateViews.empty',
      screenId: 'stateViews',
      screenLabelBuilder: (translations) => translations.devGallery.screenStateViews,
      caseLabelBuilder: (translations) => translations.devGallery.caseStateEmpty,
      stateFactory: (_) => StateViewsGalleryState.empty,
      pageFactory: (context, state) =>
          const _StateViewsPreview(state: StateViewsGalleryState.empty),
    ),
    TypedGalleryCase<StateViewsGalleryState>(
      id: 'stateViews.error',
      screenId: 'stateViews',
      screenLabelBuilder: (translations) => translations.devGallery.screenStateViews,
      caseLabelBuilder: (translations) => translations.devGallery.caseStateError,
      stateFactory: (_) => StateViewsGalleryState.error,
      pageFactory: (context, state) =>
          const _StateViewsPreview(state: StateViewsGalleryState.error),
    ),
    TypedGalleryCase<StateViewsGalleryState>(
      id: 'stateViews.loading',
      screenId: 'stateViews',
      screenLabelBuilder: (translations) => translations.devGallery.screenStateViews,
      caseLabelBuilder: (translations) => translations.devGallery.caseStateLoading,
      stateFactory: (_) => StateViewsGalleryState.loading,
      pageFactory: (context, state) =>
          const _StateViewsPreview(state: StateViewsGalleryState.loading),
    ),
  ];
}

class _StateViewsPreview extends StatelessWidget {
  const _StateViewsPreview({required this.state});

  final StateViewsGalleryState state;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final content = switch (state) {
      StateViewsGalleryState.empty => EmptyStateView(
        title: translations.states.emptyTitle,
        body: translations.states.emptyBody,
        action: (label: translations.common.retry, onTap: () {}),
      ),
      StateViewsGalleryState.error => ErrorStateView(
        title: translations.states.errorTitle,
        body: translations.states.errorBody,
        action: (label: translations.common.retry, onTap: () {}),
      ),
      StateViewsGalleryState.loading => LoadingStateView(
        title: translations.states.loadingTitle,
      ),
    };

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: content,
      ),
    );
  }
}
