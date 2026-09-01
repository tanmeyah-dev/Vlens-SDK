import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error_parser.dart';

/// Shared parsing for SDK API responses.
///
/// When the body contains `success: false`, callers should stop navigation and
/// show [message] to the user via [blockingError].
class SdkApiResponse {
  SdkApiResponse(this.raw);

  final http.Response raw;
  Map<String, dynamic>? _cachedDecoded;

  factory SdkApiResponse.from(http.Response response) =>
      SdkApiResponse(response);

  bool get isHttpOk => raw.statusCode >= 200 && raw.statusCode < 300;

  Map<String, dynamic>? get decoded {
    if (_cachedDecoded != null) return _cachedDecoded;
    final body = raw.body.trim();
    if (body.isEmpty) return null;
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic>) {
        _cachedDecoded = value;
      } else if (value is Map) {
        _cachedDecoded = Map<String, dynamic>.from(value);
      }
    } catch (_) {
      // Malformed JSON — caller may handle separately.
    }
    return _cachedDecoded;
  }

  /// `true`, `false`, or `null` when the field is absent.
  bool? get success => _readSuccess(decoded);

  bool get isBusinessFailure => success == false;

  String message({String fallback = 'حدث خطأ غير متوقع'}) {
    return ApiErrorParser.extractMessage(raw.body, fallbackMessage: fallback);
  }

  /// Returns a user-facing error when the response should block the flow.
  /// Returns `null` when the caller may continue parsing the payload.
  String? blockingError({
    bool checkHttp = true,
    bool checkBusinessSuccess = true,
    String? httpFallback,
    String? businessFallback,
  }) {
    if (checkBusinessSuccess && isBusinessFailure) {
      return message(fallback: businessFallback ?? 'حدث خطأ');
    }
    if (checkHttp && !isHttpOk) {
      final fallback = httpFallback ?? 'حدث خطأ';
      return message(fallback: '$fallback (${raw.statusCode})');
    }
    return null;
  }

  /// Used by session-expiry handling to keep validation errors on-screen.
  static bool hasBusinessFailure(http.Response response) {
    return SdkApiResponse.from(response).isBusinessFailure;
  }

  static bool? _readSuccess(Map<String, dynamic>? map) {
    if (map == null) return null;

    final root = _parseBool(map['success']);
    if (root != null) return root;

    for (final key in const ['data', 'result', 'payload']) {
      final nested = map[key];
      if (nested is Map<String, dynamic>) {
        final nestedSuccess = _readSuccess(nested);
        if (nestedSuccess != null) return nestedSuccess;
      } else if (nested is Map) {
        final nestedSuccess = _readSuccess(Map<String, dynamic>.from(nested));
        if (nestedSuccess != null) return nestedSuccess;
      }
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return null;
  }
}

extension SdkHttpResponseX on http.Response {
  SdkApiResponse get sdk => SdkApiResponse.from(this);
}
