import 'dart:convert';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

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
    final existing = await VerificationCache().getRequestTypeId();
    if (existing != null) return existing;

    final headers = await _headers();
    final response = await SdkHttpClient.get(
      Uri.parse(ApiUrls.getRequestTypesUrl()),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل أنواع الطلبات (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('استجابة غير صالحة من الخادم');
    }

    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw Exception('لا توجد أنواع طلبات متاحة');
    }

    final first = data.first;
    if (first is! Map<String, dynamic> || first['id'] == null) {
      throw Exception('تعذر قراءة نوع الطلب');
    }

    final rawId = first['id'];
    final requestTypeId = rawId is int ? rawId : int.tryParse('$rawId');
    if (requestTypeId == null) {
      throw Exception('معرف نوع الطلب غير صالح');
    }

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
    if (response.statusCode != 200) {
      throw Exception('فشل التحقق من الأهلية (${response.statusCode})');
    }

    final decodedRaw = jsonDecode(response.body);
    if (decodedRaw is! Map) {
      throw Exception('استجابة الأهلية غير صالحة');
    }
    final decoded = Map<String, dynamic>.from(decodedRaw);

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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => UserInfoScreen(eligibilityResponse: eligibility),
      ),
    );
  }
}
