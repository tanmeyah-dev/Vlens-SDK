import 'dart:convert';

import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../validate_user/constants/api_urls.dart';
import '../model/request_current_response.dart';

/// GET `/vlens/api/v1/request/current` (shared by summary flow and waiting screen).
class RequestCurrentFetcher {
  static Map<String, dynamic>? _tryDecodeMap(String rawBody) {
    if (rawBody.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore malformed JSON.
    }
    return null;
  }

  static Future<RequestCurrentResponse> fetch(
    Map<String, String> headers, {
    String logLabel = 'REQUEST_CURRENT',
  }) async {
    final currentUrl = ApiUrls.getRequestCurrentUrl();

    print('');
    print('═══════════════════════════════════════════════════════');
    print('📤 REQUEST CURRENT API CALL ($logLabel)');
    print('═══════════════════════════════════════════════════════');
    print('URL: $currentUrl');
    print('Method: GET');
    print('Headers: $headers');
    print('═══════════════════════════════════════════════════════');
    print('');

    final response = await SdkHttpClient.get(
      Uri.parse(currentUrl),
      headers: headers,
    );

    print('');
    print('═══════════════════════════════════════════════════════');
    print('📥 REQUEST CURRENT API RESPONSE ($logLabel)');
    print('═══════════════════════════════════════════════════════');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('═══════════════════════════════════════════════════════');
    print('');

    final api = SdkApiResponse.from(response);
    final blockingError = api.blockingError(
      httpFallback: 'فشل جلب الطلب الحالي',
      businessFallback: 'فشل جلب الطلب الحالي',
    );
    if (blockingError != null) {
      throw Exception(blockingError);
    }

    final decoded = api.decoded ?? _tryDecodeMap(response.body);
    if (decoded == null) {
      throw Exception('استجابة غير صالحة من request/current');
    }

    final parsed = RequestCurrentResponse.fromJson(decoded);
    return parsed;
  }
}
