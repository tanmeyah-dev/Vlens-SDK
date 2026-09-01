import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error_parser.dart';

/// Thrown when an API returns HTTP 2xx with explicit `"success": false`.
class ApiBusinessException implements Exception {
  final String message;

  ApiBusinessException(this.message);

  @override
  String toString() => message;
}

/// Validates API envelope responses for explicit business failures.
class ApiBusinessResponse {
  static const _fallbackMessage = 'حدث خطأ غير متوقع';

  /// OTP verify endpoints handle `success: false` in-dialog (stay on screen).
  static bool _shouldSkipBusinessCheck(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('/phone/verify-otp') ||
        path.endsWith('/email/verify-otp') ||
        path.endsWith('/login/verify-otp');
  }

  /// Throws [ApiBusinessException] when [response] is 2xx JSON with `success: false`.
  ///
  /// Only acts on an explicit `success` key so VLens/login payloads without it
  /// keep using their existing `isBusinessSuccess()` / computed getters.
  static void ensureSuccess(http.Response response, {Uri? requestUri}) {
    if (requestUri != null && _shouldSkipBusinessCheck(requestUri)) return;
    if (response.statusCode < 200 || response.statusCode >= 300) return;

    final body = response.body.trim();
    if (body.isEmpty) return;

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return;

      final map = Map<String, dynamic>.from(decoded);
      if (!map.containsKey('success')) return;

      final rawSuccess = map['success'];
      final isExplicitFailure = rawSuccess is bool
          ? !rawSuccess
          : rawSuccess?.toString().toLowerCase() == 'false';
      if (!isExplicitFailure) return;

      throw ApiBusinessException(
        ApiErrorParser.extractMessage(
          body,
          fallbackMessage: _fallbackMessage,
        ),
      );
    } on ApiBusinessException {
      rethrow;
    } catch (_) {
      // Ignore malformed JSON.
    }
  }
}
