import 'dart:convert';

import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:flutter/material.dart';

import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_http_client.dart';
import '../../mobile_number/constants/api_urls.dart';
import '../model/econtract_validate_otp_response.dart';
import '../scene/payment_webview_scene.dart';
import '../widget/econtract_verification_dialog.dart';
import 'device_info_helper.dart';

/// Shared e-contract: `customer/step/otp` → OTP dialog → `customer/validate/otp`.
class EContractOtpHelper {
  EContractOtpHelper._();

  static const String _emptyGuid = '00000000-0000-0000-0000-000000000000';

  /// After successful validate (no payment link), runs [onVerifiedWithoutPayment].
  static Future<void> run(
    BuildContext context,
    dynamic requestId, {
    required void Function(BuildContext context) onVerifiedWithoutPayment,
  }) async {
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

    final paymentLink = validateResponse.data?.paymentLink?.trim();
    if (paymentLink != null && paymentLink.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScene(paymentLink: paymentLink),
        ),
      );
      return;
    }

    onVerifiedWithoutPayment(context);
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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorMessage = response.statusCode == 417
            ? ApiErrorParser.extractMessage(
                response.body,
                fallbackMessage: 'فشل التحقق من OTP (${response.statusCode})',
              )
            : 'فشل التحقق من OTP (${response.statusCode})';
        throw Exception(errorMessage);
      }

      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! Map) {
        throw Exception('استجابة غير صالحة من الخادم');
      }

      final parsed = EContractValidateOtpResponse.fromJson(
        Map<String, dynamic>.from(decodedBody),
      );

      if (!parsed.success) {
        final serverMessage = parsed.data?.errorMessage?.trim();
        if (serverMessage != null && serverMessage.isNotEmpty) {
          throw Exception(serverMessage);
        }
        throw Exception(parsed.message?.trim().isNotEmpty == true
            ? parsed.message!
            : 'فشل التحقق من OTP');
      }

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
}
