import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/profile/profile_view_data.dart';

/// Reasons a [ProfileRepository] operation can fail. Mirrors `AuthFailureKind`:
/// a typed reason the UI maps to `profile.*` i18n keys rather than leaking a raw
/// status or token.
enum ProfileFailureKind {
  /// No backend is configured or reachable, or the presented session was not
  /// accepted (the backend could not authenticate the request). The caller
  /// degrades to a local default draft rather than fabricating a profile (C2).
  notConnected,

  /// A programmer or transport error not classified above (malformed response,
  /// unexpected status).
  unknown,
}

/// Typed exception thrown by every [ProfileRepository] operation. Mirrors
/// `AuthException` / `SettingsStoreException`: a typed reason the UI maps to
/// `profile.*` i18n keys, with an optional underlying [cause] that is never a
/// raw access token (the repository redacts before constructing this).
final class ProfileException implements Exception {
  const ProfileException.notConnected() : kind = ProfileFailureKind.notConnected, cause = null;

  const ProfileException.unknown([this.cause]) : kind = ProfileFailureKind.unknown;

  final ProfileFailureKind kind;

  /// The underlying error, if any. Forwarded to crash reporting already
  /// redacted; never a raw access token.
  final Object? cause;

  @override
  String toString() => 'ProfileException(${kind.name})';
}

/// The profile port.
///
/// Mirrors `AuthRepository` / `VersionGateStore`: per-operation, `Future`-
/// returning, throwing a typed [ProfileException]. **No production impl is
/// wired by default** (the no-backend rule, C2): the UI degrades to a local
/// `ProfileDraft.defaults()` and never fabricates a backend-sourced profile.
/// The optional real HTTP adapter — constructed at the composition root only
/// when a consumer provides an endpoint — implements this against the
/// test-server profile contract (`GET|PUT /v1/profile`).
abstract interface class ProfileRepository {
  /// Loads the authenticated user's profile. [accessToken] is the bearer token
  /// issued by the session auth flow. Throws [ProfileException] on any failure;
  /// the caller degrades to a local default draft (C2).
  Future<ProfileDraft> load({required String accessToken});

  /// Persists the editable fields of [draft] (`displayName`, `bio`; `email` is
  /// read-only and ignored by the backend) and returns the post-save draft as
  /// the backend echoes back the canonical shape. Throws [ProfileException] on
  /// any failure.
  Future<ProfileDraft> save({required String accessToken, required ProfileDraft draft});
}

/// Handwritten Riverpod handle for the [ProfileRepository] port.
///
/// Mirrors `authRepositoryProvider` / `otpRepositoryProvider`: it throws a
/// [StateError] until the composition root overrides it with a concrete
/// adapter. The no-backend default is constructed in `AppDependencies.production`
/// and wired in `lib/app/app.dart` as a peer of the other port overrides. No
/// codegen.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw StateError('ProfileRepository must be overridden at the composition root.'),
);
