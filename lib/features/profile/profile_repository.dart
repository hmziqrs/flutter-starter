import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/profile/profile_view_data.dart';

/// Reasons a [ProfileRepository] operation can fail; the UI maps each to a
/// `profile.*` i18n key rather than leaking a raw status or token.
enum ProfileFailureKind {
  /// No backend configured/reachable, or the session was rejected. The caller
  /// degrades to a local default draft rather than fabricating a profile.
  notConnected,

  /// Any other transport or programmer error.
  unknown,
}

/// Typed exception thrown by every [ProfileRepository] operation.
final class ProfileException implements Exception {
  const ProfileException.notConnected() : kind = ProfileFailureKind.notConnected, cause = null;

  const ProfileException.unknown([this.cause]) : kind = ProfileFailureKind.unknown;

  final ProfileFailureKind kind;

  /// Never a raw access token; redacted before construction.
  final Object? cause;

  @override
  String toString() => 'ProfileException(${kind.name})';
}

/// The profile port. No production impl is wired by default; the UI degrades
/// to a local `ProfileDraft.defaults()` rather than fabricating a
/// backend-sourced profile.
abstract interface class ProfileRepository {
  /// Throws [ProfileException] on failure; the caller degrades to a local
  /// default draft.
  Future<ProfileDraft> load({required String accessToken});

  /// Persists `displayName`/`bio` (`email` is read-only) and returns the
  /// post-save draft as echoed by the backend.
  Future<ProfileDraft> save({required String accessToken, required ProfileDraft draft});
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw StateError('ProfileRepository must be overridden at the composition root.'),
);
