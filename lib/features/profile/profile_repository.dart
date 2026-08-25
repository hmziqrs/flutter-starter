import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/shared/errors/repository_exception.dart';

enum ProfileFailureKind {
  notConnected,

  unknown,
}

final class ProfileException extends RepositoryException<ProfileFailureKind> {
  const ProfileException.notConnected() : super(kind: ProfileFailureKind.notConnected);

  const ProfileException.unknown([Object? cause])
    : super(kind: ProfileFailureKind.unknown, cause: cause);

  @override
  String toString() => describe('ProfileException');
}

abstract interface class ProfileRepository {
  Future<ProfileDraft> load({required String accessToken});

  Future<ProfileDraft> save({required String accessToken, required ProfileDraft draft});
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw StateError('ProfileRepository must be overridden at the composition root.'),
);
