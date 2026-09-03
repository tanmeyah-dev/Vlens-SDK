import 'dart:convert';

import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../login_screen/utils/device_info_helper.dart';
import '../../validate_user/constants/api_urls.dart';
import '../model/summary_answer_item.dart';

class RequestCreateException implements Exception {
  final String message;

  RequestCreateException(this.message);

  @override
  String toString() => message;
}

class RequestCreateResult {
  final dynamic requestId;

  const RequestCreateResult(this.requestId);
}

/// Creates a request via `/vlens/api/v1/request/create`.
Future<RequestCreateResult> createLoanRequest({
  required List<SummaryAnswerItem> answers,
}) async {
  final cache = VerificationCache();
  final requestTypeId = ApiUrls.kRequestTypeId;
  await cache.setRequestTypeId(requestTypeId);

  final accessToken = await cache.getAccessToken();
  final encryptedToken = await cache.getEncryptedAccessToken();
  final token = (accessToken != null && accessToken.trim().isNotEmpty)
      ? accessToken.trim()
      : (encryptedToken ?? '').trim();
  final headers = token.isNotEmpty
      ? HttpHeadersHelper.getHeadersWithAuth(token)
      : HttpHeadersHelper.getDefaultHeaders();

  final requestFieldsValues = <String, dynamic>{};
  for (final item in answers) {
    requestFieldsValues[item.key] = item.value.trim();
  }

  final body = {
    'requestTypeId': requestTypeId,
    'geoLocation': await DeviceInfoHelper.getCurrentLocation(),
    'userDeviceUtcTime': DateTime.now().toUtc().toIso8601String(),
    'requestFieldsValues': requestFieldsValues,
  };

  final url = ApiUrls.getRequestCreateUrl();
  final bodyJson = jsonEncode(body);

  if (kDebugMode) {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('📤 REQUEST CREATE API CALL (SUMMARY)');
    print('═══════════════════════════════════════════════════════');
    print('URL: $url');
    print('Method: POST');
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
    print('📥 REQUEST CREATE API RESPONSE (SUMMARY)');
    print('═══════════════════════════════════════════════════════');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  final api = SdkApiResponse.from(response);
  if (api.isUnauthorized) {
    throw const SdkUnauthorizedException();
  }
  final blockingError = api.blockingError(
    httpFallback: 'فشل إنشاء الطلب',
    businessFallback: 'فشل إنشاء الطلب',
  );
  if (blockingError != null) {
    throw RequestCreateException(blockingError);
  }

  final decoded = api.decoded ?? _tryDecodeMap(response.body);

  final createdRequestId = _extractCreatedRequestId(decoded);
  if (createdRequestId == null) {
    throw RequestCreateException('رقم الطلب الناتج من إنشاء الطلب غير متوفر');
  }

  return RequestCreateResult(createdRequestId);
}

dynamic _extractCreatedRequestId(Map<String, dynamic>? responseBody) {
  if (responseBody == null) return null;
  if (responseBody['id'] != null) return responseBody['id'];

  final data = responseBody['data'];
  if (data is Map) {
    final dataMap = Map<String, dynamic>.from(data);
    if (dataMap['id'] != null) return dataMap['id'];
    if (dataMap['requestId'] != null) return dataMap['requestId'];
  }
  return null;
}

Map<String, dynamic>? _tryDecodeMap(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}
