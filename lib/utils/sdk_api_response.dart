import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error_parser.dart';

/// Thrown when a response is unauthorized and login redirect was scheduled.
class SdkUnauthorizedException implements Exception {
  const SdkUnauthorizedException();
}

/// Shared parsing for SDK API responses.
///
/// HTTP **200** → callers run their navigation logic.
/// HTTP status **401** only → [SessionExpiredRedirect] → login.
/// Any other status (including 417/429) → callers show [blockingError] and stay
/// on the current screen.
class SdkApiResponse {
  SdkApiResponse(this.raw);

  final http.Response raw;
  Map<String, dynamic>? _cachedDecoded;

  factory SdkApiResponse.from(http.Response response) =>
      SdkApiResponse(response);

  bool get isHttpOk => raw.statusCode >= 200 && raw.statusCode < 300;

  bool get isHttp200 => raw.statusCode == 200;

  /// HTTP status **401** only.
  /// Forces a redirect to the login screen via [SessionExpiredRedirect].
  /// Used by every SDK API call through [SdkHttpClient].
  bool get isUnauthorized => raw.statusCode == 401;

  /// When `true`, stop processing — login redirect is handled by [SessionExpiredRedirect].
  bool get stopsCaller => isUnauthorized;

  static bool abortIfUnauthorized(http.Response response) {
    return SdkApiResponse.from(response).isUnauthorized;
  }

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

  /// Parsed API `code` / `error_code` from the JSON body (root or nested).
  int? get responseCode => _readResponseCode(decoded);

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
    if (isUnauthorized) return null;

    if (checkHttp && !isHttp200) {
      final fallback = httpFallback ?? 'حدث خطأ';
      return message(fallback: '$fallback (${raw.statusCode})');
    }

    if (checkBusinessSuccess && isBusinessFailure) {
      return message(fallback: businessFallback ?? 'حدث خطأ');
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

  static int? _readResponseCode(Map<String, dynamic>? map) {
    if (map == null) return null;

    for (final key in const ['code', 'error_code', 'errorCode']) {
      final parsed = _parseInt(map[key]);
      if (parsed != null) return parsed;
    }

    for (final nestedKey in const ['data', 'result', 'payload']) {
      final nested = map[nestedKey];
      if (nested is Map<String, dynamic>) {
        final nestedCode = _readResponseCode(nested);
        if (nestedCode != null) return nestedCode;
      } else if (nested is Map) {
        final nestedCode =
            _readResponseCode(Map<String, dynamic>.from(nested));
        if (nestedCode != null) return nestedCode;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString().trim());
  }
}

extension SdkHttpResponseX on http.Response {
  SdkApiResponse get sdk => SdkApiResponse.from(this);
}
