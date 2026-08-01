import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/profile/profile_view_data.dart';

enum ProfileFailureKind {
  notConnected,

  unknown,
}

final class ProfileException implements Exception {
  const ProfileException.notConnected() : kind = ProfileFailureKind.notConnected, cause = null;

  const ProfileException.unknown([this.cause]) : kind = ProfileFailureKind.unknown;

  final ProfileFailureKind kind;

  final Object? cause;

  @override
  String toString() => 'ProfileException(${kind.name})';
}

abstract interface class ProfileRepository {
  Future<ProfileDraft> load({required String accessToken});

  Future<ProfileDraft> save({required String accessToken, required ProfileDraft draft});
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw StateError('ProfileRepository must be overridden at the composition root.'),
);
