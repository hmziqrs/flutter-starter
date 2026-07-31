import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/session/auth_session.dart';

enum OtpDeliveryChannel {
  sms,
  email,
  authenticator,
}

enum OtpFailureKind {
  notConnected,

  invalid,

  unknown,
}

/// [cause] never carries a raw code or attempt token (mirrors `AuthException`).
final class OtpRepositoryException implements Exception {
  const OtpRepositoryException.notConnected() : kind = OtpFailureKind.notConnected, cause = null;

  const OtpRepositoryException.invalid([this.cause]) : kind = OtpFailureKind.invalid;

  const OtpRepositoryException.unknown([this.cause]) : kind = OtpFailureKind.unknown;

  final OtpFailureKind kind;

  final Object? cause;

  @override
  String toString() => 'OtpRepositoryException(${kind.name})';
}

/// [attemptToken] is the opaque verify handle — never reaches a widget or log.
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

enum OtpVerifyOutcome {
  valid,
  invalid,
  expired,
  locked,
}

@immutable
final class OtpVerifyResult {
  const OtpVerifyResult.valid({this.session}) : outcome = OtpVerifyOutcome.valid;
  const OtpVerifyResult.invalid() : outcome = OtpVerifyOutcome.invalid, session = null;
  const OtpVerifyResult.expired() : outcome = OtpVerifyOutcome.expired, session = null;
  const OtpVerifyResult.locked() : outcome = OtpVerifyOutcome.locked, session = null;

  final OtpVerifyOutcome outcome;

  final AuthAuthenticated? session;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtpVerifyResult && outcome == other.outcome && session == other.session;
  }

  @override
  int get hashCode => Object.hash(outcome, session);
}

abstract interface class OtpRepository {
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  });

  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  });

  Future<OtpIssueResult> resend({required String identifier});
}

final otpRepositoryProvider = Provider<OtpRepository>(
  (ref) => throw StateError('OtpRepository must be overridden at the composition root.'),
);
