import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/session/auth_session.dart';

/// Delivery channel an issued OTP was sent over, surfaced to the countdown
/// screen ("code sent to your authenticator app" vs "sent by SMS").
enum OtpDeliveryChannel {
  sms,
  email,
  authenticator,
}

/// Reasons an [OtpRepository] operation can fail, mapped to `auth.otp.*` i18n.
enum OtpFailureKind {
  /// No backend configured/reachable. The default for the unseeded
  /// `InMemoryOtpRepository` and any transport failure on the real adapter.
  notConnected,

  /// The attempt token / identifier was rejected, or the request malformed.
  invalid,

  /// A programmer or transport error not classified above.
  unknown,
}

/// Typed exception thrown by every [OtpRepository] operation. Mirrors
/// `AuthException`; [cause] is never a raw code or attempt token.
final class OtpRepositoryException implements Exception {
  const OtpRepositoryException.notConnected() : kind = OtpFailureKind.notConnected, cause = null;

  const OtpRepositoryException.invalid([this.cause]) : kind = OtpFailureKind.invalid;

  const OtpRepositoryException.unknown([this.cause]) : kind = OtpFailureKind.unknown;

  final OtpFailureKind kind;

  final Object? cause;

  @override
  String toString() => 'OtpRepositoryException(${kind.name})';
}

/// The result of issuing an OTP.
///
/// [expiresAt] drives the client-side expiry countdown, [channel] drives the
/// "where to look" copy, and [attemptToken] is the opaque handle the verify
/// step presents back to the backend (never reaches a widget or a log).
@immutable
final class OtpIssueResult {
  const OtpIssueResult({
    required this.expiresAt,
    required this.channel,
    required this.attemptToken,
  });

  final DateTime expiresAt;
  final OtpDeliveryChannel channel;
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

/// Discrete outcome of verifying a code. Both the client `AttemptTracker`
/// cooldown and the server's `429 locked` map to [locked] so the UI presents
/// one consistent lockout.
enum OtpVerifyOutcome {
  valid,
  invalid,
  expired,
  locked,
}

/// Typed verify result (discriminated union over [OtpVerifyOutcome]).
@immutable
final class OtpVerifyResult {
  const OtpVerifyResult.valid({this.session}) : outcome = OtpVerifyOutcome.valid;
  const OtpVerifyResult.invalid() : outcome = OtpVerifyOutcome.invalid, session = null;
  const OtpVerifyResult.expired() : outcome = OtpVerifyOutcome.expired, session = null;
  const OtpVerifyResult.locked() : outcome = OtpVerifyOutcome.locked, session = null;

  final OtpVerifyOutcome outcome;

  /// The session a backend issues when a **registration**-purpose verify
  /// succeeds (account activated, tokens returned inline). `null` for every
  /// other outcome/purpose; never faked.
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
/// No production impl is wired by default: `InMemoryOtpRepository` surfaces
/// `notConnected` until a consumer wires a real HTTP adapter against
/// `POST /v1/otp/{issue,verify,resend}`.
abstract interface class OtpRepository {
  /// Issues a fresh OTP for [identifier] under [purpose].
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  });

  /// Verifies [code] against the outstanding issue for [identifier]. A `429
  /// locked` from the backend agrees with the client `AttemptTracker` cooldown
  /// and surfaces [OtpVerifyResult.locked].
  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  });

  /// Re-issues a code for [identifier], returning the refreshed expiry so the
  /// controller restarts its countdown from the real value.
  Future<OtpIssueResult> resend({required String identifier});
}

/// Handwritten Riverpod handle for the [OtpRepository]. Throws until
/// overridden at the composition root; `InMemoryOtpRepository` is the
/// production default.
final otpRepositoryProvider = Provider<OtpRepository>(
  (ref) => throw StateError('OtpRepository must be overridden at the composition root.'),
);
