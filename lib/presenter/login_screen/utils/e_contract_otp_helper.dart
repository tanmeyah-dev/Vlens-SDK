import 'dart:async';
import 'dart:convert';

import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

import '../../../data/models/extracted_user_data.dart';
import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../../utils/sdk_navigator.dart';
import '../../validate_user/constants/api_urls.dart';
import '../model/econtract_validate_otp_response.dart';
import '../widget/e_contract_success_dialog.dart';
import '../widget/econtract_verification_dialog.dart';
import 'device_info_helper.dart';

/// Shared e-contract: `customer/step/otp` → OTP dialog → `customer/validate/otp`.
class EContractOtpHelper {
  EContractOtpHelper._();

  static const String _emptyGuid = '00000000-0000-0000-0000-000000000000';

  /// After ready-for-disbursement succeeds, returns to the host main screen.
  static Future<void> run(
    BuildContext context,
    dynamic requestId,
  ) async {
    final stepOk = await _fireEContractCustomerStepOtp(context, requestId);
    if (!context.mounted || !stepOk) return;

    String? enteredOtpCode;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EContractVerificationDialog(
        lastTwoDigits: '',
        onConfirm: (otpCode) {
          enteredOtpCode = otpCode;
        },
      ),
    );

    if (!context.mounted ||
        enteredOtpCode == null ||
        enteredOtpCode!.trim().isEmpty) {
      return;
    }

    final validateResponse = await _validateEContractOtp(
      context,
      requestId,
      enteredOtpCode!.trim(),
    );
    if (!context.mounted || validateResponse == null) return;

    // Fire distribution API while the success alert is visible.
    unawaited(_fireReadyForDisbursement(context, showError: false));

    final navContext = context;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EContractSuccessDialog(
        navigationContext: navContext,
        onDismiss: () {
          if (navContext.mounted) {
            SdkNavigator.returnToHostApp(navContext);
          }
        },
      ),
    );
  }

  static Future<bool> _fireEContractCustomerStepOtp(
    BuildContext context,
    dynamic requestId,
  ) async {
    try {
      final cache = VerificationCache();
      final accessToken = await cache.getAccessToken();
      final encryptedToken = await cache.getEncryptedAccessToken();
      final token = (accessToken != null && accessToken.trim().isNotEmpty)
          ? accessToken.trim()
          : (encryptedToken ?? '').trim();
      final headers = token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();

      final location = await DeviceInfoHelper.getCurrentLocation();
      final latitude = (location['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude = (location['longitude'] as num?)?.toDouble() ?? 0.0;
      final userDeviceUtcTime = DateTime.now().toUtc().toIso8601String();

      final transactionId = await _resolveTransactionIdForEContract(cache);
      if (transactionId == null) {
        throw Exception('رقم العملية غير متوفر');
      }

      final body = {
        'requestId': requestId,
        'geoLocation': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'transactionId': transactionId,
        'userDeviceUtcTime': userDeviceUtcTime,
      };

      final url = ApiUrls.getEContractCustomerStepOtpUrl();
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 E-CONTRACT CUSTOMER STEP OTP API CALL');
      print('═══════════════════════════════════════════════════════');
      print('URL: $url');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: $body');
      print('═══════════════════════════════════════════════════════');
      print('');

      final jsonResponse = await SdkHttpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 E-CONTRACT CUSTOMER STEP OTP API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${jsonResponse.statusCode}');
      print('Body: ${jsonResponse.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (jsonResponse.statusCode < 200 || jsonResponse.statusCode >= 300) {
        final errorMessage = jsonResponse.statusCode == 417
            ? ApiErrorParser.extractMessage(
                jsonResponse.body,
                fallbackMessage:
                    'فشل تفعيل خطوة OTP للعقد الإلكتروني (${jsonResponse.statusCode})',
              )
            : 'فشل تفعيل خطوة OTP للعقد الإلكتروني (${jsonResponse.statusCode})';
        throw Exception(errorMessage);
      }

      final blockingError = SdkApiResponse.from(jsonResponse).blockingError(
        checkHttp: false,
        businessFallback: 'فشل تفعيل خطوة OTP للعقد الإلكتروني',
      );
      if (blockingError != null) {
        throw Exception(blockingError);
      }
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
  }

  static Future<String?> _resolveTransactionIdForEContract(
    VerificationCache cache,
  ) async {
    final cachedTransactionId = (await cache.getTransactionId())?.trim();
    if (_isUsableTransactionId(cachedTransactionId)) {
      return cachedTransactionId;
    }

    final cachedVlensData = await cache.getVlensExtractedData();
    final vlensTransactionId = _extractTransactionIdFromDynamic(cachedVlensData);
    if (_isUsableTransactionId(vlensTransactionId)) {
      return vlensTransactionId;
    }

    final cachedLoginResponse = await cache.getLoginResponseData();
    final loginTransactionId = _extractTransactionIdFromDynamic(cachedLoginResponse);
    if (_isUsableTransactionId(loginTransactionId)) {
      return loginTransactionId;
    }

    return null;
  }

  static String? _extractTransactionIdFromDynamic(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final direct = map['transactionId']?.toString().trim();
      if (_isUsableTransactionId(direct)) return direct;
      final snake = map['transaction_id']?.toString().trim();
      if (_isUsableTransactionId(snake)) return snake;

      for (final entry in map.values) {
        final nested = _extractTransactionIdFromDynamic(entry);
        if (_isUsableTransactionId(nested)) return nested;
      }
      return null;
    }

    if (value is List) {
      for (final item in value) {
        final nested = _extractTransactionIdFromDynamic(item);
        if (_isUsableTransactionId(nested)) return nested;
      }
    }
    return null;
  }

  static bool _isUsableTransactionId(String? transactionId) {
    if (transactionId == null || transactionId.isEmpty) return false;
    return transactionId != _emptyGuid;
  }

  static Future<EContractValidateOtpResponse?> _validateEContractOtp(
    BuildContext context,
    dynamic requestId,
    String otpCode,
  ) async {
    try {
      final cache = VerificationCache();
      final transactionId = await _resolveTransactionIdForEContract(cache);
      if (transactionId == null) {
        throw Exception('رقم العملية غير متوفر');
      }

      final accessToken = await cache.getAccessToken();
      final encryptedToken = await cache.getEncryptedAccessToken();
      final token = (accessToken != null && accessToken.trim().isNotEmpty)
          ? accessToken.trim()
          : (encryptedToken ?? '').trim();
      final headers = token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();

      final location = await DeviceInfoHelper.getCurrentLocation();
      final latitude = (location['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude = (location['longitude'] as num?)?.toDouble() ?? 0.0;
      final userDeviceUtcTime = DateTime.now().toUtc().toIso8601String();

      final body = {
        'requestId': requestId.toString(),
        'otpCode': otpCode,
        'transactionId': transactionId,
        'geoLocation': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'userDeviceUtcTime': userDeviceUtcTime,
      };

      final url = ApiUrls.getEContractCustomerValidateOtpUrl();
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 E-CONTRACT CUSTOMER VALIDATE OTP API CALL');
      print('═══════════════════════════════════════════════════════');
      print('URL: $url');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');
      print('═══════════════════════════════════════════════════════');
      print('');

      final response = await SdkHttpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 E-CONTRACT CUSTOMER VALIDATE OTP API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      final api = SdkApiResponse.from(response);
      final blockingError = api.blockingError(
        httpFallback: 'فشل التحقق من OTP',
        businessFallback: 'فشل التحقق من OTP',
      );
      if (blockingError != null) {
        throw Exception(blockingError);
      }

      final decodedBody = api.decoded;
      if (decodedBody == null) {
        throw Exception('استجابة غير صالحة من الخادم');
      }

      final parsed = EContractValidateOtpResponse.fromJson(decodedBody);

      return parsed;
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return null;
    }
  }

  /// POST ready-for-disbursement after e-contract OTP validate. Returns false on error.
  static Future<bool> _fireReadyForDisbursement(
    BuildContext context, {
    bool showError = true,
  }) async {
    try {
      final cache = VerificationCache();
      final nationalId = await _resolveCachedNationalId(cache);
      if (nationalId == null || nationalId.isEmpty) {
        throw Exception('الرقم القومي غير متوفر');
      }

      final accessToken = await cache.getAccessToken();
      final encryptedToken = await cache.getEncryptedAccessToken();
      final token = (accessToken != null && accessToken.trim().isNotEmpty)
          ? accessToken.trim()
          : (encryptedToken ?? '').trim();
      final headers = token.isNotEmpty
          ? HttpHeadersHelper.getHeadersWithAuth(token)
          : HttpHeadersHelper.getDefaultHeaders();

      final url = ApiUrls.getReadyForDisbursementUrl();
      final body = {'nationalId': nationalId};

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 READY-FOR-DISBURSEMENT API CALL');
      print('═══════════════════════════════════════════════════════');
      print('URL: $url');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');
      print('═══════════════════════════════════════════════════════');
      print('');

      final response = await SdkHttpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 READY-FOR-DISBURSEMENT API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      final api = SdkApiResponse.from(response);
      final blockingError = api.blockingError(
        httpFallback: 'فشل تجهيز القرض للصرف',
        businessFallback: 'فشل تجهيز القرض للصرف',
      );
      if (blockingError != null) {
        throw Exception(blockingError);
      }

      return true;
    } catch (e) {
      print('❌ Ready-for-disbursement failed: $e');
      if (!showError || !context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
  }

  static Future<String?> _resolveCachedNationalId(VerificationCache cache) async {
    final persisted = (await cache.getNationalId())?.trim();
    if (persisted != null && persisted.isNotEmpty) return persisted;

    final fromVlens = _nationalIdFromVlens(await cache.getVlensExtractedData());
    if (fromVlens != null) return fromVlens;

    final fromTrace = _extractNationalIdFromDynamic(
      await cache.getVlensTraceResponseBody(),
    );
    if (fromTrace != null) return fromTrace;

    final fromLogin = _extractNationalIdFromDynamic(
      await cache.getLoginResponseData(),
    );
    if (fromLogin != null) return fromLogin;

    return null;
  }

  static String? _nationalIdFromVlens(dynamic cached) {
    if (cached == null) return null;

    ExtractedUserData? data;
    if (cached is ExtractedUserData) {
      data = cached;
    } else if (cached is Map<String, dynamic>) {
      data = ExtractedUserData.fromJson(cached);
    } else if (cached is Map) {
      data = ExtractedUserData.fromJson(Map<String, dynamic>.from(cached));
    }

    final fromModel = data?.idFrontData?.idNumber?.trim() ??
        data?.idBackData?.idNumber?.trim() ??
        data?.user?.idNumber?.trim();
    if (fromModel != null && fromModel.isNotEmpty) return fromModel;

    return _extractNationalIdFromDynamic(cached);
  }

  static String? _extractNationalIdFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in const [
        'idNumber',
        'nationalId',
        'nationalID',
        'NationalId',
        'id_number',
        'CIF_ID',
        'cifId',
      ]) {
        final direct = map[key]?.toString().trim();
        if (_isUsableNationalId(direct)) return direct;
      }
      final userName = map['userName']?.toString().trim();
      if (_looksLikeNationalId(userName)) return userName;
      for (final entry in map.values) {
        final nested = _extractNationalIdFromDynamic(entry);
        if (nested != null && nested.isNotEmpty) return nested;
      }
      return null;
    }
    if (value is List) {
      for (final item in value) {
        final nested = _extractNationalIdFromDynamic(item);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  static bool _isUsableNationalId(String? value) {
    if (value == null || value.isEmpty) return false;
    return value != _emptyGuid;
  }

  static bool _looksLikeNationalId(String? value) {
    if (value == null || value.isEmpty) return false;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 14;
  }
}
