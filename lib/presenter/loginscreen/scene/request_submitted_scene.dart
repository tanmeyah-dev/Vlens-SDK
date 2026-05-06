import 'dart:convert';

import 'package:core/components/button/app_button.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';
import '../model/econtract_validate_otp_response.dart';
import 'payment_webview_scene.dart';
import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_http_client.dart';
import '../../mobile_number/constants/api_urls.dart';
import '../utils/device_info_helper.dart';
import '../widget/econtract_verification_dialog.dart';

/// Package name from [pubspec.yaml]; required for asset resolution from host apps.
const String _tanSdkPackageName = 'tan_sdk';

class RequestSubmittedScene extends StatefulWidget {
  final dynamic requestId;

  const RequestSubmittedScene({
    super.key,
    required this.requestId,
  });

  @override
  State<RequestSubmittedScene> createState() => _RequestSubmittedSceneState();
}

class _RequestSubmittedSceneState extends State<RequestSubmittedScene> {
  static const String _emptyGuid = '00000000-0000-0000-0000-000000000000';

  Future<bool> _fireEContractCustomerStepOtp() async {
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
        'requestId': widget.requestId,
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
      print('📤 E-CONTRACT CUSTOMER STEP OTP API CALL (REQUEST SUBMITTED)');
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
      print('📥 E-CONTRACT CUSTOMER STEP OTP API RESPONSE (REQUEST SUBMITTED)');
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
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
  }

  Future<String?> _resolveTransactionIdForEContract(VerificationCache cache) async {
    final cachedTransactionId = (await cache.getTransactionId())?.trim();
    if (_isUsableTransactionId(cachedTransactionId)) {
      return cachedTransactionId;
    }

    // Fallback 1: transaction id inside cached VLens extracted payload.
    final cachedVlensData = await cache.getVlensExtractedData();
    final vlensTransactionId = _extractTransactionIdFromDynamic(cachedVlensData);
    if (_isUsableTransactionId(vlensTransactionId)) {
      return vlensTransactionId;
    }

    // Fallback 2: transaction id inside cached login response payload.
    final cachedLoginResponse = await cache.getLoginResponseData();
    final loginTransactionId = _extractTransactionIdFromDynamic(cachedLoginResponse);
    if (_isUsableTransactionId(loginTransactionId)) {
      return loginTransactionId;
    }

    return null;
  }

  String? _extractTransactionIdFromDynamic(dynamic value) {
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

  bool _isUsableTransactionId(String? transactionId) {
    if (transactionId == null || transactionId.isEmpty) return false;
    return transactionId != _emptyGuid;
  }

  Future<void> _onDonePressed(BuildContext context) async {
    final stepOtpTriggered = await _fireEContractCustomerStepOtp();
    if (!context.mounted || !stepOtpTriggered) return;

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

    if (!context.mounted || enteredOtpCode == null || enteredOtpCode!.isEmpty) return;
    final validateResponse = await _validateEContractOtp(enteredOtpCode!);
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تأكيد التعاقد الإلكتروني بنجاح'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<EContractValidateOtpResponse?> _validateEContractOtp(String otpCode) async {
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
        'requestId': widget.requestId.toString(),
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
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: AppButton(
              title: 'حسناً',
              backgroundColor: AppColors.blue,
              onPressed: () => _onDonePressed(context),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'طلب تمويل',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 36 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Container(
                    color: AppColors.white,
                    child: Image.asset(
                      AppAssets.requestSubmitted,
                      package: _tanSdkPackageName,
                      width: 330,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'حسنًا..!',
                    style: TextStyle(
                      color: Color(0xFF2E2B77),
                      fontSize: 34 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لقد تم ارسال طلبك بنجاح برجاء انتظار الموافقة على طلبك ليتم توقيعك للعقد الالكتروني '
                      'وصرف التمويل المطلوب',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 30 / 2,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
