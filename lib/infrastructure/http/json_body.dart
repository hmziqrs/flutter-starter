import 'dart:convert';

import 'package:dio/dio.dart';

/// Shared JSON body parsing primitives used by the Dio-backed HTTP repositories.
///
/// These helpers exist to keep the per-feature clients focused on their own
/// status-bucket rules and view-data mapping instead of duplicating the same
/// string/date/decode logic across files.

/// Returns [raw] when it is a non-empty [String], otherwise `null`.
String? asString(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;

/// Parses [raw] as an ISO-8601 [DateTime], returning `null` when malformed.
DateTime? parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } on FormatException {
    return null;
  }
}

/// Decodes [response]'s body into a `Map<String, Object?>`.
///
/// An empty body yields an empty map. Any decode failure or non-map payload is
/// funneled through [errorFactory], which must throw the caller's feature
/// exception (its return type is [Never]). Each caller decides its own
/// exception style, so the error type is intentionally not constrained here;
/// the [Object] argument carries the underlying decode error for callers that
/// want to inspect it.
Map<String, Object?> decodeJsonMap(
  Response<dynamic> response, {
  required Never Function(Object error) errorFactory,
}) {
  final body = response.data;
  if (body == null) return const <String, Object?>{};
  final text = body is String ? body : body.toString();
  if (text.isEmpty) return const <String, Object?>{};
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
  } on FormatException catch (e) {
    errorFactory(e);
  }
  errorFactory(const _NonObjectJsonError());
}

/// Tolerant variant of decodeJsonMap: returns an empty map on decode failure
/// or a non-map payload instead of throwing. Used by clients that intentionally
/// ignore malformed bodies (e.g. OTP verify, which inspects the status code).
Map<String, Object?> decodeJsonMapOrEmpty(Response<dynamic> response) {
  final body = response.data;
  if (body == null) return const <String, Object?>{};
  final text = body is String ? body : body.toString();
  if (text.isEmpty) return const <String, Object?>{};
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
  } on FormatException {
    // ignored — tolerant callers treat malformed bodies as empty.
  }
  return const <String, Object?>{};
}

/// Sentinel passed to decodeJsonMap's errorFactory when the decoded payload is
/// not a JSON object.
class _NonObjectJsonError {
  const _NonObjectJsonError();
}
