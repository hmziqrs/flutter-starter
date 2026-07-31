import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';

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
