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

List<RouteBase> buildProfileRoutes() => [
  GoRoute(
    name: AppRoutes.updateProfile,
    path: AppRoutes.updateProfilePath,
    builder: (context, state) => const UpdateProfileRoutePage(),
  ),
];

class UpdateProfileRoutePage extends StatefulWidget {
  const UpdateProfileRoutePage({super.key});

  @override
  State<UpdateProfileRoutePage> createState() => _UpdateProfileRoutePageState();
}

class _UpdateProfileRoutePageState extends State<UpdateProfileRoutePage> {
  late final Future<ProfileDraft> _initialDraftLoad;

  @override
  void initState() {
    super.initState();
    final container = ProviderScope.containerOf(context, listen: false);
    final session = container.read(sessionControllerProvider);
    final accessToken = session is AuthAuthenticated ? session.accessToken : '';
    _initialDraftLoad = container.read(profileRepositoryProvider).load(accessToken: accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileDraft>(
      future: _initialDraftLoad,
      builder: (context, snapshot) {
        final draft = snapshot.hasData ? snapshot.data! : const ProfileDraft.defaults();
        return UpdateProfilePage(
          initialDraft: draft,
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
            }
          },
        );
      },
    );
  }
}
