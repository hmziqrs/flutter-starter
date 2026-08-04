import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/infrastructure/http/app_http_repository.dart';
import 'package:starter/infrastructure/http/json_body.dart';

final class HttpOtpClient extends AppHttpRepository implements OtpRepository {
  HttpOtpClient({required super.baseUrl, super.dio});

  final Map<String, String> _attemptTokens = <String, String>{};

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
      throw const OtpRepositoryException.invalid();
    }
    final result = await _send(
      path: '/v1/otp/verify',
      body: <String, Object>{'attempt_token': attemptToken, 'code': code},
    );
    final status = result.status;
    final body = result.body;
    if (status == 409) {
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
      final accessToken = asString(body['access_token']);
      final refreshToken = asString(body['refresh_token']);
      final expiresAt = parseDate(body['expires_at']);
      final userId = asString(body['user_id']);
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
    classify(status);
  }

  @override
  Future<OtpIssueResult> resend({required String identifier}) {
    final purpose = _purposes[identifier] ?? OtpPurpose.registration;
    return _issue(path: '/v1/otp/resend', purpose: purpose, identifier: identifier);
  }

  @override
  Never classify(int status) {
    if (status >= 500) {
      throw const OtpRepositoryException.notConnected();
    }
    if (status >= 400 && status < 500) {
      throw const OtpRepositoryException.invalid();
    }
    throw const OtpRepositoryException.notConnected();
  }

  @override
  Never throwNotConnected() => throw const OtpRepositoryException.notConnected();

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
      classify(result.status);
    }
    final envelope = _parseIssueEnvelope(result.body);
    _attemptTokens[identifier] = envelope.attemptToken;
    _purposes[identifier] = purpose;
    return envelope;
  }

  Future<({int status, Map<String, Object?> body})> _send({
    required String path,
    required Map<String, Object> body,
  }) async {
    final response = await roundTripRaw(
      () => dio.post<String>(
        path,
        data: jsonEncode(body),
        options: Options(
          responseType: ResponseType.plain,
          contentType: Headers.jsonContentType,
          headers: <String, String>{'X-Api-Key': 'dev'},
        ),
      ),
    );
    return (status: response.statusCode!, body: decodeJsonMapOrEmpty(response));
  }

  OtpIssueResult _parseIssueEnvelope(Map<String, Object?> body) {
    final attemptToken = asString(body['attempt_token']);
    final expiresAt = parseDate(body['expires_at']);
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
}
