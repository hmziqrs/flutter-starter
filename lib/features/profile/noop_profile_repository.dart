import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';

/// No-op [ProfileRepository] for the no-backend production default.
///
/// Mirrors `InMemoryAuthRepository` / `InMemoryOtpRepository`. Honors the
/// no-backend rule (C2) and the honest-feedback guardrail: `load` / `save` both
/// surface `ProfileException.notConnected` and **never fake success** — no
/// fabricated profile, no silent save. The profile screen therefore degrades to
/// `ProfileDraft.defaults()` until a consumer wires the optional real HTTP
/// adapter (`HttpProfileRepository`).
///
/// This default is distinct from a genuinely test-only fake: it is constructed
/// in `AppDependencies.production` (when no endpoint is configured) and
/// `AppDependencies.inMemory`, and is the production default until
/// `AppConfig.backendBaseUrl` is set. A test that wants to drive the live
/// load/save paths injects a fake [ProfileRepository] override instead.
final class NoopProfileRepository implements ProfileRepository {
  const NoopProfileRepository();

  @override
  Future<ProfileDraft> load({required String accessToken}) async {
    // No backend: surface notConnected rather than fabricating a profile. The
    // caller degrades to a local default draft (never a backend-sourced shape).
    throw const ProfileException.notConnected();
  }

  @override
  Future<ProfileDraft> save({
    required String accessToken,
    required ProfileDraft draft,
  }) async {
    // No backend: surface notConnected rather than silently swallowing the
    // save. A silent no-op would let the UI believe the profile was persisted.
    throw const ProfileException.notConnected();
  }
}
