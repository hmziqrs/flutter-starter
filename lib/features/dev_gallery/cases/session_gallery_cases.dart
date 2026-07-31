import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/session/session_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';

part 'session_gallery_cases.freezed.dart';

@Freezed(copyWith: false)
class SessionGalleryState with _$SessionGalleryState {
  const SessionGalleryState._(this.viewData, this.labelBuilder);

  @override
  final SessionViewData viewData;
  @override
  final String Function(Translations translations) labelBuilder;

  static final loggedOut = SessionGalleryState._(
    const SessionViewData.anonymous(),
    (t) => t.devGallery.caseSessionLoggedOut,
  );
  static final loggedIn = SessionGalleryState._(
    const SessionViewData(isSignedIn: true, userId: 'demo-user'),
    (t) => t.devGallery.caseSessionLoggedIn,
  );

  static final values = <SessionGalleryState>[loggedOut, loggedIn];
}

List<GalleryCase> buildSessionGalleryCases() {
  return [
    for (final entry in SessionGalleryState.values)
      TypedGalleryCase<SessionGalleryState>(
        id: 'session.${entry.viewData.isSignedIn ? 'loggedIn' : 'loggedOut'}',
        screenId: 'session',
        screenLabelBuilder: (translations) => translations.devGallery.screenSession,
        caseLabelBuilder: entry.labelBuilder,
        stateFactory: (_) => entry,
        pageFactory: (context, state) => _SessionPreview(state: state),
      ),
  ];
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({required this.state});

  final SessionGalleryState state;

  @override
  Widget build(BuildContext context) {
    final viewData = state.viewData;
    final identity = viewData.userId;
    final summary = viewData.isSignedIn
        ? context.t.session.signedInPreview(userId: identity ?? '')
        : context.t.session.signedOut;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.t.devGallery.preview,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
