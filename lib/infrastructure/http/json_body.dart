import 'dart:convert';

import 'package:dio/dio.dart';

String? asString(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;

DateTime? parseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return DateTime.parse(raw);
  } on FormatException {
    return null;
  }
}

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
  } on FormatException {}
  return const <String, Object?>{};
}

class _NonObjectJsonError {
  const _NonObjectJsonError();
}
