import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/profile/update_profile_page.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/media/media_picker.dart';

List<RouteBase> buildProfileRoutes() => [
  GoRoute(
    name: AppRoutes.updateProfile,
    path: AppRoutes.updateProfilePath,
    builder: (context, state) => const UpdateProfileRoutePage(),
  ),
];

class UpdateProfileRoutePage extends ConsumerStatefulWidget {
  const UpdateProfileRoutePage({super.key});

  @override
  ConsumerState<UpdateProfileRoutePage> createState() => _UpdateProfileRoutePageState();
}

class _UpdateProfileRoutePageState extends ConsumerState<UpdateProfileRoutePage> {
  PickedMedia? _pickedAvatar;
  String? _loadedToken;
  Future<ProfileDraft>? _draftLoad;

  /// One shared future per access token: watching the session must not re-fire
  /// the load on unrelated rebuilds, and a rotated token reloads deliberately.
  Future<ProfileDraft> _draftLoadFor(AuthAuthenticated session) {
    final existing = _draftLoad;
    if (existing != null && _loadedToken == session.accessToken) {
      return existing;
    }
    _loadedToken = session.accessToken;
    return _draftLoad = ref.read(profileRepositoryProvider).load(accessToken: session.accessToken);
  }

  @override
  Widget build(BuildContext context) {
    // Watched, not read once: on a cold start restored into /profile/edit the
    // session hydrates from secure storage post-frame, and the page must flip
    // from the anonymous sign-in state to the form when it lands.
    final session = ref.watch(sessionControllerProvider);
    final authenticated = session is AuthAuthenticated ? session : null;
    return FutureBuilder<ProfileDraft>(
      future: authenticated == null ? null : _draftLoadFor(authenticated),
      builder: (context, snapshot) {
        final draft = snapshot.hasData ? snapshot.data! : const ProfileDraft.defaults();
        return UpdateProfilePage(
          initialDraft: draft,
          pickedAvatar: _pickedAvatar,
          isAnonymous: authenticated == null,
          onSignIn: () => context.pushNamed(AppRoutes.login),
          onContinueAsGuest: () => context.go(AppRoutes.homePath),
          onSave: (draft) async {
            final container = ProviderScope.containerOf(context, listen: false);
            final session = container.read(sessionControllerProvider);
            final accessToken = session is AuthAuthenticated ? session.accessToken : '';
            try {
              await container
                  .read(profileRepositoryProvider)
                  .save(accessToken: accessToken, draft: draft);
              if (!context.mounted) return;
              showAppInformationDialog(
                context,
                title: context.t.common.success,
                body: context.t.profile.update.saved,
              );
            } on ProfileException {
              if (!context.mounted) return;
              showAppInformationDialog(
                context,
                title: context.t.common.legalPlaceholderTitle,
                body: context.t.common.notConnected,
              );
            }
          },
          onAvatarPicked: (media) {
            if (media == null) {
              showAppInformationDialog(
                context,
                title: context.t.profile.update.changeAvatar,
                body: context.t.profile.update.avatarUnavailable,
              );
              return;
            }
            setState(() => _pickedAvatar = media);
          },
        );
      },
    );
  }
}
