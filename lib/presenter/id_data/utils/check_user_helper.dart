import 'dart:convert';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';

import '../../../data/models/extracted_user_data.dart';
import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../validate_user/constants/api_urls.dart';

class CheckUserResult {
  const CheckUserResult._({
    required this.success,
    this.message,
  });

  const CheckUserResult.matched() : this._(success: true);

  const CheckUserResult.failed(String message)
      : this._(success: false, message: message);

  final bool success;
  final String? message;
}

/// POST `/cma/check-user` with scanned national ID and login mobile number.
class CheckUserHelper {
  CheckUserHelper._();

  static const _fallbackError =
      'برجاء التأكد من تطابق رقم البطاقة المستخدمة مع رقم البطاقة عند إنشاء حساب على التطبيق.';

  static Future<CheckUserResult> check({
    required ExtractedUserData? extractedData,
  }) async {
    final nationalId = _nationalIdFromExtracted(extractedData);
    if (nationalId == null) {
      throw Exception('رقم الهوية غير متوفر للتحقق');
    }

    final mobileNumber = await _resolveLoggedInMobileNumber();
    if (mobileNumber == null) {
      throw Exception('رقم الموبايل غير متوفر للتحقق');
    }

    final cache = VerificationCache();
    final token = (await cache.getAccessToken())?.trim();
    final encrypted = (await cache.getEncryptedAccessToken())?.trim();
    final authToken = (token != null && token.isNotEmpty) ? token : encrypted;
    final headers = authToken != null && authToken.isNotEmpty
        ? HttpHeadersHelper.getHeadersWithAuth(authToken)
        : HttpHeadersHelper.getDefaultHeaders();

    final response = await SdkHttpClient.post(
      Uri.parse(ApiUrls.getCheckUserUrl()),
      headers: headers,
      body: jsonEncode({
        'nationalId': nationalId,
        'mobileNumber': mobileNumber,
      }),
    );

    final api = SdkApiResponse.from(response);
    if (api.isUnauthorized) {
      throw const SdkUnauthorizedException();
    }

    if (api.success == true) {
      return const CheckUserResult.matched();
    }

    return CheckUserResult.failed(
      api.message(fallback: _fallbackError),
    );
  }

  static String? _nationalIdFromExtracted(ExtractedUserData? data) {
    if (data == null) return null;
    for (final value in [
      data.idFrontData?.idNumber,
      data.idBackData?.idNumber,
      data.user?.idNumber,
    ]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }

    final json = data.toJson();
    return _firstNonEmpty(json, const [
      'idNumber',
      'nationalId',
      'nationalID',
      'id_number',
    ]);
  }

  static String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    for (final nestedKey in const ['idFrontData', 'idBackData', 'user']) {
      final nested = map[nestedKey];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        for (final key in keys) {
          final value = nestedMap[key]?.toString().trim();
          if (value != null && value.isNotEmpty) return value;
        }
      }
    }
    return null;
  }

  static Future<String?> _resolveLoggedInMobileNumber() async {
    final cache = VerificationCache();

    final cachedMobile = (await cache.getMobileNumber())?.trim();
    if (cachedMobile != null && cachedMobile.isNotEmpty) {
      return cachedMobile;
    }

    final cachedUserName = (await cache.getUserName())?.trim();
    if (cachedUserName != null && cachedUserName.isNotEmpty) {
      return cachedUserName;
    }

    final loginData = await cache.getLoginResponseData();
    if (loginData is Map) {
      final map = Map<String, dynamic>.from(loginData);
      for (final key in const [
        'userName',
        'username',
        'phoneNumber',
        'mobileNumber',
        'mobile',
      ]) {
        final value = map[key]?.toString().trim();
        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() != 'null') {
          return value;
        }
      }
      final data = map['data'];
      if (data is Map) {
        final nested = Map<String, dynamic>.from(data);
        for (final key in const [
          'userName',
          'username',
          'phoneNumber',
          'mobileNumber',
          'mobile',
        ]) {
          final value = nested[key]?.toString().trim();
          if (value != null &&
              value.isNotEmpty &&
              value.toLowerCase() != 'null') {
            return value;
          }
        }
      }
    }
    return null;
  }
}
