import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';

/// No-op [ProfileRepository] production default until a real HTTP adapter is
/// wired: both operations surface `notConnected` rather than fabricating a
/// profile or silently swallowing a save.
final class NoopProfileRepository implements ProfileRepository {
  const NoopProfileRepository();

  @override
  Future<ProfileDraft> load({required String accessToken}) async {
    throw const ProfileException.notConnected();
  }

  @override
  Future<ProfileDraft> save({
    required String accessToken,
    required ProfileDraft draft,
  }) async {
    throw const ProfileException.notConnected();
  }
}
