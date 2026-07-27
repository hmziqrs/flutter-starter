import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';
import 'package:starter/shared/widgets/states/error_state_view.dart';
import 'package:starter/shared/widgets/states/loading_state_view.dart';

/// Immutable, deterministic preview state for the state-views gallery cases.
///
/// One variant per canonical async-list state (empty / error / loading). No
/// timers, no async work, no persistence (C2: the gallery never fakes a backend
/// action — the retry `onTap` is a no-op preview callback, never a claim of
/// success).
enum StateViewsGalleryState {
  /// The empty-list state, with a primary call-to-action affordance.
  empty,

  /// The failed-load state, with a feature-supplied retry affordance whose
  /// label reuses `common.retry`.
  error,

  /// The in-flight state, built around the shared `BusyIndicator`.
  loading,
}

/// Builds the state-views gallery cases: an [EmptyStateView], an
/// [ErrorStateView], and a [LoadingStateView]. Every case is a static fixture
/// wired to deterministic, localized copy. The error case's retry action is a
/// no-op preview callback (the gallery never fakes a backend action); a real
/// call site wires it to surface `common.notConnected`.
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

/// Frames each state-view variant inside the gallery's constrained content
/// column. The state-view card itself is the production surface under test;
/// this wrapper only centers and pads it.
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
        // No-op preview callback — the gallery never fakes a backend action.
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }
}
