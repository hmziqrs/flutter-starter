import 'package:dio/dio.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

/// [FeedbackTransport] that POSTs to the contract-C3 feedback ingest routes
/// (`POST /v1/feedback`, `GET /v1/feedback/{id}/status`). The optional real
/// implementation from feedback.md — never constructed by the starter itself
/// (`AppDependencies.production` stays on `NoopFeedbackTransport`); a consumer
/// overrides [feedbackTransportProvider] with an instance built from their
/// backend base URL (+ timeouts and auth headers via an injected `Dio`). Never
/// throws: 201 → accepted, 422/413 → rejected, everything else (including
/// connection failures) → unavailable.
final class HttpFeedbackTransport implements FeedbackTransport {
  HttpFeedbackTransport({required Uri baseUrl, Dio? dio}) : _dio = dio ?? buildAppDio(baseUrl);

  static const int _created = 201;
  static const int _payloadTooLarge = 413;
  static const int _unprocessableEntity = 422;

  final Dio _dio;

  @override
  Future<FeedbackResult> submit(FeedbackSubmission submission) async {
    final Response<Object?> response;
    try {
      response = await _dio.post<Object?>('/v1/feedback', data: _encode(submission));
    } on Object catch (error) {
      return FeedbackResult.unavailable(error);
    }
    return switch (response.statusCode) {
      _created => _accepted(response.data),
      _unprocessableEntity || _payloadTooLarge => const FeedbackResult.rejected(),
      _ => FeedbackResult.unavailable('HTTP ${response.statusCode}'),
    };
  }

  @override
  Future<FeedbackTriageState> status(String id) async {
    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>('/v1/feedback/${Uri.encodeComponent(id)}/status');
    } on Object {
      return FeedbackTriageState.unavailable;
    }
    if (response.statusCode != 200) {
      return FeedbackTriageState.unavailable;
    }
    final data = response.data;
    final state = data is Map<String, Object?> ? data['state'] : null;
    return switch (state) {
      'queued' => FeedbackTriageState.queued,
      'triaged' => FeedbackTriageState.triaged,
      _ => FeedbackTriageState.unavailable,
    };
  }

  FeedbackResult _accepted(Object? data) {
    final id = data is Map<String, Object?> ? data['id'] : null;
    if (id is String && id.isNotEmpty) {
      return FeedbackResult.accepted(id);
    }
    return const FeedbackResult.unavailable('201 without an id');
  }

  Map<String, Object?> _encode(FeedbackSubmission submission) {
    return <String, Object?>{
      'message': submission.message,
      'email': ?submission.email,
      'screenshotMime': ?submission.screenshotMime,
      'screenshotBase64': ?submission.screenshotBase64,
      'appMetadata': <String, Object?>{
        'version': submission.appMetadata.appVersion,
        'platform': submission.appMetadata.platform,
        'locale': submission.appMetadata.locale,
      },
    };
  }
}
