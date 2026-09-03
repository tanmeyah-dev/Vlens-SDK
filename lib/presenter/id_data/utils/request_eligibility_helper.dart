import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../user_info/scene/user_info_screen.dart';
import '../../validate_user/constants/api_urls.dart';

/// Loads request-type + eligibility, then opens [UserInfoScreen].
class RequestEligibilityHelper {
  static Future<String?> resolveToken() async {
    final cache = VerificationCache();
    final access = await cache.getAccessToken();
    if (access != null && access.trim().isNotEmpty) {
      return access.trim();
    }
    final encrypted = await cache.getEncryptedAccessToken();
    if (encrypted != null && encrypted.trim().isNotEmpty) {
      return encrypted.trim();
    }
    return null;
  }

  static Future<Map<String, String>> _headers() async {
    final token = await resolveToken();
    return token != null && token.isNotEmpty
        ? HttpHeadersHelper.getHeadersWithAuth(token)
        : HttpHeadersHelper.getDefaultHeaders();
  }

  static Future<int> ensureRequestTypeIdCached() async {
    const requestTypeId = ApiUrls.kRequestTypeId;
    await VerificationCache().setRequestTypeId(requestTypeId);
    return requestTypeId;
  }

  static Future<Map<String, dynamic>> fetchEligibilityResponse() async {
    await ensureRequestTypeIdCached();

    final headers = await _headers();
    final response = await SdkHttpClient.get(
      Uri.parse(ApiUrls.getRequestEligibilityUrl()),
      headers: headers,
    );
    final api = SdkApiResponse.from(response);
    if (api.isUnauthorized) {
      throw const SdkUnauthorizedException();
    }
    final blockingError = api.blockingError(
      httpFallback: 'فشل التحقق من الأهلية',
      businessFallback: 'فشل التحقق من الأهلية',
    );
    if (blockingError != null) {
      throw Exception(blockingError);
    }

    final decoded = api.decoded;
    if (decoded == null) {
      throw Exception('استجابة الأهلية غير صالحة');
    }

    final data = decoded['data'];
    final isEligible = data is Map && data['isEligible'] == true;
    if (!isEligible) {
      throw Exception('عذراً، المستخدم غير مؤهل حالياً');
    }
    return decoded;
  }

  static Future<void> openUserInfoScreen(BuildContext context) async {
    final eligibility = await fetchEligibilityResponse();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserInfoScreen(eligibilityResponse: eligibility),
      ),
    );
  }
}
