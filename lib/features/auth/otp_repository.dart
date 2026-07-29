import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/session/auth_session.dart';

/// Delivery channel an issued OTP was sent over. Surfaced to the UI so the
/// countdown screen can tell the user where to look ("code sent to your
/// authenticator app" vs "sent by SMS"). The no-backend default never produces
/// a value here — `InMemoryOtpRepository` throws before construction.
enum OtpDeliveryChannel {
  sms,
  email,
  authenticator,
}

/// Reasons an [OtpRepository] operation can fail. Surfaced to the UI through
/// [OtpRepositoryException] -> i18n; the honest no-backend default surfaces
/// [notConnected] rather than fabricating an issued code (C2).
enum OtpFailureKind {
  /// No backend is configured or reachable. The default for the unseeded
  /// `InMemoryOtpRepository` and for any transport failure on the real adapter.
  notConnected,

  /// The attempt token / identifier was rejected, or the request was malformed.
  invalid,

  /// A programmer or transport error not classified above.
  unknown,
}

/// Typed exception thrown by every [OtpRepository] operation. Mirrors
/// `AuthException` / `SettingsStoreException`: a typed reason the UI maps to
/// `auth.otp.*` i18n keys, with an optional underlying [cause] that is never a
/// raw code or attempt token (the repository redacts before constructing this).
final class OtpRepositoryException implements Exception {
  const OtpRepositoryException.notConnected() : kind = OtpFailureKind.notConnected, cause = null;

  const OtpRepositoryException.invalid([this.cause]) : kind = OtpFailureKind.invalid;

  const OtpRepositoryException.unknown([this.cause]) : kind = OtpFailureKind.unknown;

  final OtpFailureKind kind;

  /// The underlying error, if any. Forwarded to crash reporting already
  /// redacted; never a raw code or attempt token.
  final Object? cause;

  @override
  String toString() => 'OtpRepositoryException(${kind.name})';
}

/// The result of issuing an OTP. A handwritten typed value: never a `Map`.
///
/// [expiresAt] drives the client-side expiry countdown (the controller owns the
/// `Timer`), [channel] drives the "where to look" copy, and [attemptToken] is
/// the opaque handle the verify step presents back to the backend. The token is
/// held by the repository / controller and never reaches a widget or a log.
@immutable
final class OtpIssueResult {
  const OtpIssueResult({
    required this.expiresAt,
    required this.channel,
    required this.attemptToken,
  });

  /// Absolute wall-clock expiry of the issued code. The controller derives
  /// `remainingSeconds` from this and the injected clock.
  final DateTime expiresAt;

  /// Channel the code was delivered over.
  final OtpDeliveryChannel channel;

  /// Opaque backend handle for the verify step. Redacted in any error path.
  final String attemptToken;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtpIssueResult &&
            expiresAt == other.expiresAt &&
            channel == other.channel &&
            attemptToken == other.attemptToken;
  }

  @override
  int get hashCode => Object.hash(expiresAt, channel, attemptToken);
}

/// Discrete outcome of verifying a code. The client `AttemptTracker` cooldown
/// and the server's `429 locked` both map to [OtpVerifyOutcome.locked] so the
/// UI presents one consistent lockout (contracts.md C2 — the local tracker is
/// the UX source of truth for the cooldown seconds).
enum OtpVerifyOutcome {
  valid,
  invalid,
  expired,
  locked,
}

/// Typed verify result. A handwritten discriminated union over
/// [OtpVerifyOutcome]; never a `Map` or a `bool`. The controller exhaustive-
/// switches on [outcome] (strict-analysis clean — no default arm).
@immutable
final class OtpVerifyResult {
  const OtpVerifyResult.valid({this.session}) : outcome = OtpVerifyOutcome.valid;
  const OtpVerifyResult.invalid() : outcome = OtpVerifyOutcome.invalid, session = null;
  const OtpVerifyResult.expired() : outcome = OtpVerifyOutcome.expired, session = null;
  const OtpVerifyResult.locked() : outcome = OtpVerifyOutcome.locked, session = null;

  final OtpVerifyOutcome outcome;

  /// The session a backend issues when a **registration**-purpose verify
  /// succeeds (it activates the pending account and returns tokens inline, so
  /// the flow can log in without a separate credential round-trip). `null` for
  /// every other outcome and every other purpose; the caller establishes the
  /// session only when this is present. Never faked (C2).
  final AuthAuthenticated? session;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtpVerifyResult && outcome == other.outcome && session == other.session;
  }

  @override
  int get hashCode => Object.hash(outcome, session);
}

/// The OTP delivery + verification port.
///
/// Mirrors `AuthRepository` / `VersionGateStore`: per-operation, `Future`-
/// returning, throwing a typed [OtpRepositoryException]. **No production impl is
/// wired by default** (the no-backend rule, C2): the `InMemoryOtpRepository`
/// default surfaces `OtpRepositoryException.notConnected` when unseeded and
/// never fakes a successful issue/verify/resend — the OTP screen stays a
/// faithful static demo until a consumer wires a real impl. The optional real
/// HTTP adapter (a consumer-owned HTTP adapter under
/// `lib/infrastructure/auth/`) implements this against the test-server contract
/// (`POST /v1/otp/{issue,verify,resend}`) and is constructed only when an
/// endpoint is configured.
abstract interface class OtpRepository {
  /// Issues a fresh OTP for [identifier] under [purpose], returning the expiry,
  /// delivery channel, and opaque attempt handle. Throws
  /// [OtpRepositoryException] on any failure.
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  });

  /// Verifies the entered [code] against the outstanding issue for [identifier]
  /// and returns the typed outcome. The backend maps `identifier` -> its held
  /// attempt token; a `429 locked` agrees with the client `AttemptTracker`
  /// cooldown and surfaces [OtpVerifyResult.locked]. Throws
  /// [OtpRepositoryException] only when no backend is reachable.
  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  });

  /// Re-issues a code for [identifier] (the test server returns a refreshed
  /// `expires_at`), returning the new [OtpIssueResult] so the controller can
  /// restart its countdown from the real refreshed expiry rather than a
  /// redundant follow-up `issue` call.
  ///
  /// Throws [OtpRepositoryException] on any failure; rate-limited server-side.
  Future<OtpIssueResult> resend({required String identifier});
}

/// Handwritten Riverpod handle for the [OtpRepository]. Overridden at the App
/// `ProviderScope`; throws until wired (mirrors `authRepositoryProvider` /
/// `settingsStoreProvider`). The production default is `InMemoryOtpRepository`
/// (constructed in `AppDependencies.production`); the optional real HTTP adapter
/// is a consumer override only.
final otpRepositoryProvider = Provider<OtpRepository>(
  (ref) => throw StateError('OtpRepository must be overridden at the composition root.'),
);
