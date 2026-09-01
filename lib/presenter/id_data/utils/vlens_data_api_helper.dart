import 'dart:convert';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:tan_sdk/data/models/extracted_user_data.dart';

import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../login_screen/utils/device_info_helper.dart';
import '../../validate_user/constants/api_urls.dart';
import 'id_data_parser.dart';

class VlensDataApiException implements Exception {
  final String message;

  VlensDataApiException(this.message);

  @override
  String toString() => message;
}

/// Builds the request body expected by `/vlens/api/v1/request/vlens-data`.
Future<Map<String, dynamic>> buildVlensDataRequestBody(
  ExtractedUserData data, {
  String? phoneNumber,
}) async {
  final deviceInfo = await DeviceInfoHelper.getVlensDeviceInfoPayload();

  return {
    'isVerificationProcessCompleted':
        data.isVerificationProcessCompleted ?? true,
    'isDigitalIdentityVerified': data.isDigitalIdentityVerified ?? true,
    'deviceInfo': deviceInfo,
    'phoneNumber': phoneNumber ?? '',
    'user': _buildUserPayload(data.user),
    'idFrontData': data.idFrontData?.toJson() ?? <String, dynamic>{},
    'idBackData': data.idBackData?.toJson() ?? <String, dynamic>{},
  };
}

/// Sends `user: null` when extracted VLens data has no usable user fields
/// (instead of `{ userId: "", email: "", ... }`).
Map<String, dynamic>? _buildUserPayload(User? user) {
  if (user == null) return null;

  final userId = user.id?.toString().trim() ?? '';
  final email = user.emailAddress?.trim() ?? '';
  final phoneNumber = user.phoneNumber?.trim() ?? '';
  final username = user.userName?.trim() ?? '';

  final hasAnyValue = userId.isNotEmpty ||
      email.isNotEmpty ||
      phoneNumber.isNotEmpty ||
      username.isNotEmpty;
  if (!hasAnyValue) return null;

  return {
    'userId': userId,
    'email': email,
    'phoneNumber': phoneNumber,
    'username': username,
  };
}

/// POST extracted VLens data after verification success.
/// URL has no query param; cached `phoneNumber` is sent in the body.
Future<void> submitVlensData(
  ExtractedUserData data, {
  String? phoneNumber,
}) async {
  final token = await _resolveToken();
  final headers = token != null && token.isNotEmpty
      ? HttpHeadersHelper.getHeadersWithAuth(token)
      : HttpHeadersHelper.getDefaultHeaders();

  // Prefer cache (login mobile / userName) — VLens extracted user is often null.
  final resolvedPhone = await _resolvePhoneNumberFromCache(
    preferred: phoneNumber,
  );
  if (resolvedPhone == null || resolvedPhone.isEmpty) {
    throw VlensDataApiException('رقم الهاتف غير متوفر لإرسال بيانات الهوية');
  }

  final body = await buildVlensDataRequestBody(
    data,
    phoneNumber: resolvedPhone,
  );
  final url = ApiUrls.getVlensDataUrl();
  final bodyJson = jsonEncode(body);

  if (kDebugMode) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📤 VLENS DATA SUBMIT API CALL');
    print('═══════════════════════════════════════════════════════');
    print('URL: $url');
    print('Method: POST');
    print('phoneNumber (body from cache): $resolvedPhone');
    print('Headers: $headers');
    print('Body: $bodyJson');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  final response = await SdkHttpClient.post(
    Uri.parse(url),
    headers: headers,
    body: bodyJson,
  );

  if (kDebugMode) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📥 VLENS DATA SUBMIT API RESPONSE');
    print('═══════════════════════════════════════════════════════');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  final api = SdkApiResponse.from(response);
  final blockingError = api.blockingError(
    httpFallback: 'فشل إرسال بيانات الهوية',
    businessFallback: 'فشل إرسال بيانات الهوية',
  );
  if (blockingError != null) {
    throw VlensDataApiException(blockingError);
  }
}

/// GET previously submitted VLens extracted data for [phoneNumber].
/// When [phoneNumber] is omitted, uses the cached mobile number from login.
Future<ExtractedUserData?> fetchVlensData({String? phoneNumber}) async {
  final token = await _resolveToken();
  final headers = token != null && token.isNotEmpty
      ? HttpHeadersHelper.getHeadersWithAuth(token)
      : HttpHeadersHelper.getDefaultHeaders();

  final resolvedPhone = await _resolvePhoneNumberFromCache(
    preferred: phoneNumber,
  );
  if (resolvedPhone == null || resolvedPhone.isEmpty) {
    throw VlensDataApiException('رقم الهاتف غير متوفر لتحميل بيانات الهوية');
  }

  final url = ApiUrls.getVlensDataUrl(phoneNumber: resolvedPhone);

  if (kDebugMode) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📥 VLENS DATA FETCH API CALL');
    print('═══════════════════════════════════════════════════════');
    print('URL: $url');
    print('Method: GET');
    print('phoneNumber: $resolvedPhone');
    print('Headers: $headers');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  final response = await SdkHttpClient.get(
    Uri.parse(url),
    headers: headers,
  );

  if (kDebugMode) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📥 VLENS DATA FETCH API RESPONSE');
    print('═══════════════════════════════════════════════════════');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  final api = SdkApiResponse.from(response);
  final blockingError = api.blockingError(
    httpFallback: 'فشل تحميل بيانات الهوية',
    businessFallback: 'فشل تحميل بيانات الهوية',
  );
  if (blockingError != null) {
    throw VlensDataApiException(blockingError);
  }

  final payload = _extractPayloadMap(response.body);
  if (payload == null) {
    throw VlensDataApiException('استجابة بيانات الهوية غير صالحة');
  }

  return parseExtractedUserData(payload);
}

/// Resolves phone for `/vlens-data?phoneNumber=...` from cached user data.
/// Order: preferred override → cached mobile → cached userName → login response.
Future<String?> _resolvePhoneNumberFromCache({String? preferred}) async {
  final fromPreferred = preferred?.trim();
  if (fromPreferred != null && fromPreferred.isNotEmpty) {
    return fromPreferred;
  }

  final cache = VerificationCache();

  final cachedMobile = (await cache.getMobileNumber())?.trim();
  if (cachedMobile != null && cachedMobile.isNotEmpty) {
    if (kDebugMode) {
      print('📱 vlens-data phone from cache mobileNumber: $cachedMobile');
    }
    return cachedMobile;
  }

  final cachedUserName = (await cache.getUserName())?.trim();
  if (cachedUserName != null && cachedUserName.isNotEmpty) {
    if (kDebugMode) {
      print('📱 vlens-data phone from cache userName: $cachedUserName');
    }
    return cachedUserName;
  }

  final loginData = await cache.getLoginResponseData();
  final fromLogin = _phoneFromLoginCache(loginData);
  if (fromLogin != null && fromLogin.isNotEmpty) {
    if (kDebugMode) {
      print('📱 vlens-data phone from cached login response: $fromLogin');
    }
    // Keep mobile cache in sync for later calls.
    await cache.setMobileNumber(fromLogin);
    return fromLogin;
  }

  if (kDebugMode) {
    print('⚠️ vlens-data: no phoneNumber found in cache');
  }
  return null;
}

String? _phoneFromLoginCache(dynamic loginData) {
  if (loginData == null) return null;
  Map<String, dynamic>? map;
  if (loginData is Map<String, dynamic>) {
    map = loginData;
  } else if (loginData is Map) {
    map = Map<String, dynamic>.from(loginData);
  }
  if (map == null) return null;

  String? pick(List<String> keys) {
    for (final key in keys) {
      final value = map![key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  final root = pick(const [
    'userName',
    'username',
    'phoneNumber',
    'mobileNumber',
    'mobile',
  ]);
  if (root != null) return root;

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
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
  }
  return null;
}

Map<String, dynamic>? _extractPayloadMap(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      // Response may be the vlens-data object at the root.
      if (map.containsKey('idFrontData') ||
          map.containsKey('idBackData') ||
          map.containsKey('user') ||
          map.containsKey('isVerificationProcessCompleted')) {
        return map;
      }
    }
  } catch (_) {
    // Fall through.
  }
  return null;
}

Future<String?> _resolveToken() async {
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
