import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../accounts.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Lifetime of an issued OTP code. Long enough for a human to type the code,
/// short enough to make the expiry deterministic in integration tests.
const Duration _codeTtl = Duration(seconds: 90);

/// Failed verify attempts before the server-side lockout fires. Matches the
/// client `AttemptTracker`'s `freeAttemptsBeforeLockout` so the two lockout
/// schedules agree (the OTP spec: the server 429 cooldown and the client
/// cooldown surface ONE consistent lockout to the UI).
const int _freeAttemptsBeforeLockout = 2;

/// Server-side lockout cooldown. Agrees with the auth-ratelimit schedule's
/// first non-zero cooldown so a `429 locked` from the server matches the
/// client tracker's `lockedSeconds`.
const Duration _lockedTtl = Duration(seconds: 30);

/// The literal code issued for development requests (`X-Api-Key: dev`) so an
/// integration test can enter a fixed value instead of reading `dev_code`.
/// Non-dev requests get a pseudo-random code from [_generateCode].
const String _devCode = '123456';

/// In-memory table of outstanding OTP issues: `attempt_token -> _IssuedOtp`.
///
/// The verify step keys off the attempt token the client preserved from the
/// issue response. A verified or expired code is removed; a locked identifier
/// stays in the table (with `lockedUntil`) so subsequent verifies surface 429
/// until the cooldown elapses.
final Map<String, _IssuedOtp> _issues = <String, _IssuedOtp>{};

/// Monotonic counter combined with a microsecond timestamp so attempt tokens
/// never collide within a single server process.
int _counter = 0;

String _issueToken() {
  _counter += 1;
  return 'ot-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_counter';
}

DateTime _now() => DateTime.now().toUtc();

/// Mounts the OTP contract (C9) onto [router]:
/// - `POST /v1/otp/issue`   `{purpose, identifier}` -> `{attempt_token, expires_at, channel, dev_code?}`.
/// - `POST /v1/otp/verify`  `{attempt_token, code}` -> `{valid: true}` (or `{valid: true, access_token,
///   refresh_token, expires_at, user_id}` for a registration success), `{valid: false}`, `409 expired`, or `429 locked`.
/// - `POST /v1/otp/resend`  `{identifier, purpose}` -> `{attempt_token, expires_at, channel, dev_code?}`.
///
/// `dev_code` is a test affordance: returned **only** when the request carries
/// the development API key (the `X-Api-Key: dev` header, matching the rest of
/// the test server's dev affordances). It lets an integration test read the
/// issued code without a real channel; it is never returned for any other key
/// and never logged.
void registerRoutes(Router router) {
  router.post('/v1/otp/issue', _issue);
  router.post('/v1/otp/verify', _verify);
  router.post('/v1/otp/resend', _resend);
}

/// Issues an OTP for [identifier] / [purpose] and returns the snake_case
/// envelope the issue and resend handlers (and `/v1/auth/register`) emit.
///
/// [isDev] controls two things together: the generated code is the literal
/// [_devCode] (so a test entering "123456" succeeds), and `dev_code` is
/// included in the returned envelope. Keeping the two coupled means a non-dev
/// caller never learns the code from this call.
///
/// This is the single source of truth for issuing an OTP — `/v1/auth/register`
/// reuses it so registration and standalone issue share attempt-token, code,
/// and dev_code behavior.
Map<String, Object> issueOtpEnvelope({
  required String purpose,
  required String identifier,
  required bool isDev,
}) {
  final code = _generateCode(isDev);
  final attemptToken = _issueToken();
  final expiresAt = _now().add(_codeTtl);
  _issues[attemptToken] = _IssuedOtp(
    attemptToken: attemptToken,
    identifier: identifier,
    purpose: purpose,
    code: code,
    expiresAt: expiresAt,
    failedAttempts: 0,
  );
  // Remove any prior outstanding issue for this identifier — a fresh issue
  // supersedes the previous one so the client never verifies a stale code.
  _removeByIdentifier(identifier, keep: attemptToken);

  return <String, Object>{
    'attempt_token': attemptToken,
    'expires_at': expiresAt.toIso8601String(),
    'channel': 'sms',
    if (isDev) 'dev_code': code,
  };
}

Future<Response> _issue(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final purpose = decoded['purpose'];
  final identifier = decoded['identifier'];
  if (purpose is! String ||
      purpose.isEmpty ||
      !_isKnownPurpose(purpose) ||
      identifier is! String ||
      identifier.isEmpty) {
    return _invalid();
  }
  // A locked identifier stays locked: re-issuing does not escape the cooldown.
  final existing = _findByIdentifier(identifier);
  if (existing != null && existing.isLockedAt(_now())) {
    return _lockedResponse(existing.lockedUntil!);
  }
  final envelope = issueOtpEnvelope(
    purpose: purpose,
    identifier: identifier,
    isDev: _isDevRequest(request),
  );
  return Response.ok(jsonEncode(envelope), headers: _jsonHeaders);
}

Future<Response> _verify(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final attemptToken = decoded['attempt_token'];
  final code = decoded['code'];
  if (attemptToken is! String || attemptToken.isEmpty || code is! String || code.isEmpty) {
    return _invalid();
  }
  final issued = _issues[attemptToken];
  if (issued == null) {
    // Unknown / already-consumed attempt token. Treat as expired so the client
    // surfaces the same UX path as a genuine expiry.
    return _expiredResponse();
  }
  final now = _now();
  if (issued.isLockedAt(now)) {
    return _lockedResponse(issued.lockedUntil!);
  }
  if (issued.isExpiredAt(now)) {
    _issues.remove(attemptToken);
    return _expiredResponse();
  }
  if (issued.code != code) {
    final failed = issued.failedAttempts + 1;
    if (failed > _freeAttemptsBeforeLockout) {
      // The next failure after the free allowance locks the identifier for
      // the cooldown — agrees with the client `AttemptTracker` schedule.
      final lockedUntil = now.add(_lockedTtl);
      _issues[attemptToken] = issued.copyWith(failedAttempts: failed, lockedUntil: lockedUntil);
      return _lockedResponse(lockedUntil);
    }
    _issues[attemptToken] = issued.copyWith(failedAttempts: failed);
    return Response.ok(jsonEncode(<String, Object>{'valid': false}), headers: _jsonHeaders);
  }
  // Success: consume the attempt token so a replay yields expired (409).
  _issues.remove(attemptToken);
  // A registration verify also activates the pending account and mints a
  // session so the client can call authenticated routes immediately. Other
  // purposes (mfa, password-reset) return the plain {valid: true} envelope.
  if (issued.purpose == 'registration') {
    final account = findAccountByEmail(issued.identifier);
    if (account != null && account.status == AccountStatus.pending) {
      activateAccount(account);
      return Response.ok(
        jsonEncode(<String, Object>{
          'valid': true,
          'access_token': issueAccessToken(account.userId),
          'refresh_token': issueRefreshToken(account.userId),
          'expires_at': _now().add(accessTtl).toIso8601String(),
          'user_id': account.userId,
        }),
        headers: _jsonHeaders,
      );
    }
  }
  return Response.ok(jsonEncode(<String, Object>{'valid': true}), headers: _jsonHeaders);
}

Future<Response> _resend(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final identifier = decoded['identifier'];
  final purpose = decoded['purpose'];
  if (identifier is! String ||
      identifier.isEmpty ||
      purpose is! String ||
      purpose.isEmpty ||
      !_isKnownPurpose(purpose)) {
    return _invalid();
  }
  final existing = _findByIdentifier(identifier);
  if (existing != null && existing.isLockedAt(_now())) {
    return _lockedResponse(existing.lockedUntil!);
  }
  final envelope = issueOtpEnvelope(
    purpose: purpose,
    identifier: identifier,
    isDev: _isDevRequest(request),
  );
  return Response.ok(jsonEncode(envelope), headers: _jsonHeaders);
}

bool _isKnownPurpose(String purpose) {
  return switch (purpose) {
    'registration' || 'password-reset' || 'mfa' => true,
    _ => false,
  };
}

/// Generates a 6-digit code as a zero-padded string. Development requests get
/// the fixed literal [_devCode] so an integration test entering "123456"
/// verifies successfully; everyone else gets a pseudo-random code (the test
/// server is single-process and the code is only delivered via the `dev_code`
/// affordance, never via a real channel).
String _generateCode(bool isDev) {
  if (isDev) {
    return _devCode;
  }
  final value = DateTime.now().microsecondsSinceEpoch % 1000000;
  return value.toString().padLeft(6, '0');
}

_IssuedOtp? _findByIdentifier(String identifier) {
  for (final issued in _issues.values) {
    if (issued.identifier == identifier) return issued;
  }
  return null;
}

void _removeByIdentifier(String identifier, {required String keep}) {
  final toRemove = <String>[];
  for (final entry in _issues.entries) {
    if (entry.key != keep && entry.value.identifier == identifier) {
      toRemove.add(entry.key);
    }
  }
  for (final key in toRemove) {
    _issues.remove(key);
  }
}

bool _isDevRequest(Request request) => request.headers['x-api-key'] == 'dev';

Response _invalid() => Response(
  400,
  body: jsonEncode(<String, String>{'error': 'invalid json'}),
  headers: _jsonHeaders,
);

Response _expiredResponse() =>
    Response(409, body: jsonEncode(<String, String>{'error': 'expired'}), headers: _jsonHeaders);

Response _lockedResponse(DateTime lockedUntil) {
  final retryAfter = lockedUntil.difference(_now()).inSeconds;
  return Response(
    429,
    body: jsonEncode(<String, Object>{
      'error': 'locked',
      // Clamp to non-negative; a race at the boundary could otherwise surface
      // a sub-zero window to the client.
      'retry_after_seconds': retryAfter < 0 ? 0 : retryAfter,
    }),
    headers: _jsonHeaders,
  );
}

Future<Map<String, dynamic>?> _decode(Request request) async {
  try {
    final body = await request.readAsString();
    if (body.isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  } on FormatException {
    return null;
  }
}

final class _IssuedOtp {
  const _IssuedOtp({
    required this.attemptToken,
    required this.identifier,
    required this.purpose,
    required this.code,
    required this.expiresAt,
    required this.failedAttempts,
    this.lockedUntil,
  });

  final String attemptToken;
  final String identifier;
  final String purpose;
  final String code;
  final DateTime expiresAt;
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && now.isBefore(until);
  }

  _IssuedOtp copyWith({int? failedAttempts, DateTime? lockedUntil}) {
    return _IssuedOtp(
      attemptToken: attemptToken,
      identifier: identifier,
      purpose: purpose,
      code: code,
      expiresAt: expiresAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
}
