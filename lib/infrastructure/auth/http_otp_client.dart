import 'dart:convert';

// `comment_references` flags doc cross-references to the sibling session/otp
// types imported only via the feature package; the references are intentional.
// ignore_for_file: comment_references

import 'package:dio/dio.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

/// Real HTTP [OtpRepository] against the test-server OTP contract (C9).
///
/// Constructed **only when a consumer provides an endpoint** (the no-backend
/// rule, C2: the `InMemoryOtpRepository` default surfaces
/// `OtpRepositoryException.notConnected` and never fakes an issue/verify).
/// Mirrors `HttpNotificationsRegistrationClient` / `HttpAuthClient`: speaks to
/// the backend through a shared injected [Dio] (built via [buildAppDio] when no
/// instance is supplied), native-only.
///
/// **Stateful**: the backend keys verify off an opaque `attempt_token` returned
/// by `issue`, but the port presents verify/resend in terms of the user-facing
/// [identifier]. This client holds the `identifier -> attemptToken` (and
/// `identifier -> OtpPurpose` for resend) mapping in memory so the controller
/// never handles a raw attempt token. The mapping is per-process and never
/// persisted; a cold start must re-issue.
///
/// Every interaction is wrapped in `try/on`. Transport failures (any
/// [DioException] without a response) surface
/// [OtpRepositoryException.notConnected]; an unknown attempt token (no prior
/// `issue`) or any non-2xx/429-classified `4xx` surfaces
/// [OtpRepositoryException.invalid]; verify maps `409 -> expired`, `429 ->
/// locked`, `{valid:false} -> invalid`, and `{valid:true}` (with tokens only on
/// registration-purpose success) to the matching [OtpVerifyResult]. The client
/// never fabricates a valid result (C2).
final class HttpOtpClient implements OtpRepository {
  HttpOtpClient({required Uri baseUrl, Dio? dio}) : _dio = dio ?? buildAppDio(baseUrl);

  final Dio _dio;

  /// identifier -> last issued attempt token. Seeded by `issue` / `resend`;
  /// consumed (removed) on a successful verify.
  final Map<String, String> _attemptTokens = <String, String>{};

  /// identifier -> last used purpose, so `resend` (which takes no purpose) can
  /// re-issue under the same flow as the original `issue`.
  final Map<String, OtpPurpose> _purposes = <String, OtpPurpose>{};

  @override
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  }) => _issue(path: '/v1/otp/issue', purpose: purpose, identifier: identifier);

  @override
  Future<OtpVerifyResult> verify({required String identifier, required String code}) async {
    final attemptToken = _attemptTokens[identifier];
    if (attemptToken == null) {
      // No outstanding issue for this identifier — the caller must issue first.
      throw const OtpRepositoryException.invalid();
    }
    final result = await _send(
      path: '/v1/otp/verify',
      body: <String, Object>{'attempt_token': attemptToken, 'code': code},
    );
    final status = result.status;
    final body = result.body;
    if (status == 409) {
      // The attempt token is unknown/expired server-side; drop our stale copy.
      _attemptTokens.remove(identifier);
      return const OtpVerifyResult.expired();
    }
    if (status == 429) {
      return const OtpVerifyResult.locked();
    }
    if (status == 200) {
      final valid = body['valid'];
      if (valid is! bool || !valid) {
        return const OtpVerifyResult.invalid();
      }
      // {valid: true}. Tokens arrive ONLY for a registration-purpose success
      // (the backend activates the pending account and mints a session inline).
      // Every other purpose returns {valid: true} with no tokens -> the caller
      // establishes no session from this result.
      final accessToken = _asString(body['access_token']);
      final refreshToken = _asString(body['refresh_token']);
      final expiresAt = _parseDate(body['expires_at']);
      final userId = _asString(body['user_id']);
      _attemptTokens.remove(identifier);
      if (accessToken == null || refreshToken == null || expiresAt == null || userId == null) {
        return const OtpVerifyResult.valid();
      }
      return OtpVerifyResult.valid(
        session: AuthAuthenticated(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
          userId: userId,
        ),
      );
    }
    _classifyStatus(status);
  }

  @override
  Future<OtpIssueResult> resend({required String identifier}) {
    // resend takes no purpose in the port; re-issue under the last known
    // purpose for this identifier (defaults to registration, matching the
    // initial registration -> OTP -> verify flow).
    final purpose = _purposes[identifier] ?? OtpPurpose.registration;
    return _issue(path: '/v1/otp/resend', purpose: purpose, identifier: identifier);
  }

  // --------------------------- HTTP plumbing ----------------------------

  Future<OtpIssueResult> _issue({
    required String path,
    required OtpPurpose purpose,
    required String identifier,
  }) async {
    final result = await _send(
      path: path,
      body: <String, Object>{'purpose': purpose.pathSegment, 'identifier': identifier},
    );
    if (result.status != 200) {
      _classifyStatus(result.status);
    }
    final envelope = _parseIssueEnvelope(result.body);
    _attemptTokens[identifier] = envelope.attemptToken;
    _purposes[identifier] = purpose;
    return envelope;
  }

  /// Posts a JSON body and returns the status and the decoded body so callers
  /// (`verify`) can branch on status **and** inspect the `{valid: ...}` payload.
  /// Always sends the `X-Api-Key: dev` header so the dev path's fixed code
  /// (`123456`) is issued — this is the test / dev adapter only.
  Future<({int status, Map<String, Object?> body})> _send({
    required String path,
    required Map<String, Object> body,
  }) async {
    final Response<String> response;
    try {
      response = await _dio.post<String>(
        path,
        data: jsonEncode(body),
        options: Options(
          responseType: ResponseType.plain,
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-Api-Key': 'dev'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null) {
        _classifyStatus(status);
      }
      throw const OtpRepositoryException.notConnected();
    }
    return (status: response.statusCode!, body: _decodeBody(response.data ?? ''));
  }

  Never _classifyStatus(int status) {
    if (status >= 500) {
      throw const OtpRepositoryException.notConnected();
    }
    if (status >= 400 && status < 500) {
      throw const OtpRepositoryException.invalid();
    }
    throw const OtpRepositoryException.notConnected();
  }

  OtpIssueResult _parseIssueEnvelope(Map<String, Object?> body) {
    final attemptToken = _asString(body['attempt_token']);
    final expiresAt = _parseDate(body['expires_at']);
    if (attemptToken == null || expiresAt == null) {
      throw const OtpRepositoryException.unknown();
    }
    return OtpIssueResult(
      expiresAt: expiresAt,
      channel: _parseChannel(body['channel']),
      attemptToken: attemptToken,
    );
  }

  static OtpDeliveryChannel _parseChannel(Object? raw) {
    return switch (raw) {
      'sms' => OtpDeliveryChannel.sms,
      'email' => OtpDeliveryChannel.email,
      _ => OtpDeliveryChannel.authenticator,
    };
  }

  static Map<String, Object?> _decodeBody(String body) {
    if (body.isEmpty) return const <String, Object?>{};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
    } on FormatException {
      // Fall through to an empty body so the caller classifies by status.
    }
    return const <String, Object?>{};
  }

  static String? _asString(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } on FormatException {
      return null;
    }
  }
}
