import 'dart:convert';

import 'package:http/http.dart' as http;

/// Shared helpers for `{ code, message, success, data? }` API envelopes.
class ApiResponseEnvelope {
  static bool isOtpVerifyEndpoint(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('/phone/verify-otp') ||
        path.endsWith('/email/verify-otp') ||
        path.endsWith('/login/verify-otp');
  }

  /// `true` when JSON body contains explicit `"success": false`.
  static bool isExplicitFailure(http.Response response) {
    final map = tryDecodeMap(response.body);
    if (map == null || !map.containsKey('success')) return false;

    final rawSuccess = map['success'];
    if (rawSuccess is bool) return !rawSuccess;
    return rawSuccess?.toString().toLowerCase() == 'false';
  }

  static bool? parseExplicitSuccess(Map<String, dynamic> json) {
    if (!json.containsKey('success')) return null;
    final raw = json['success'];
    if (raw is bool) return raw;
    if (raw == null) return false;
    return raw.toString().toLowerCase() == 'true';
  }

  static int? parseCode(Map<String, dynamic> json) {
    final raw = json['code'] ?? json['error_code'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
  }

  static String? parseMessage(Map<String, dynamic> json) {
    for (final key in const [
      'message',
      'Message',
      'error_message',
      'errorMessage',
    ]) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static Map<String, dynamic>? tryDecodeMap(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore malformed JSON.
    }
    return null;
  }
}
