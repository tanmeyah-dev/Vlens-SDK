import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../utils/sdk_http_client.dart';
import '../../mobile_number/constants/api_urls.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:vlens/vlens.dart';
import '../utils/device_info_helper.dart';
import '../model/login_response.dart';
import '../../home/scene/home_scene.dart';

class VerifyUserOTPDialog extends StatefulWidget {
  final String? phoneNumber;
  final String? password;
  final String? maskedPhoneNumber;
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final BuildContext? parentContext;

  const VerifyUserOTPDialog({
    super.key,
    this.phoneNumber,
    this.password,
    this.maskedPhoneNumber,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.parentContext,
  });

  @override
  State<VerifyUserOTPDialog> createState() => _VerifyUserOTPDialogState();
}

class _VerifyUserOTPDialogState extends State<VerifyUserOTPDialog> {
  int countdown = 30;
  bool canResend = false;
  Timer? countdownTimer;
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  String get _apiUrlLogin => ApiUrls.getLoginUrl();

  @override
  void initState() {
    super.initState();
    // Start countdown timer
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (countdown > 0) {
          setState(() {
            countdown--;
          });
        } else {
          timer.cancel();
          setState(() {
            canResend = true;
          });
        }
      }
    });

    // Listen to PIN changes
    pinController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔐 VERIFY USER OTP START');
    print('═══════════════════════════════════════════════════════');
    print('OTP Length: ${pinController.text.length}');
    print('Has Phone (widget): ${widget.phoneNumber?.isNotEmpty == true}');
    print('Has Password (widget): ${widget.password?.isNotEmpty == true}');
    print(
        'Has phoneNumberOtpRequestId (widget): ${widget.phoneNumberOtpRequestId?.isNotEmpty == true}');
    print('═══════════════════════════════════════════════════════');
    print('');

    if (pinController.text.length != 6) {
      print('❌ OTP validation failed: OTP must be 6 digits');
      _showError('يرجى إدخال الكود المكون من ٦ أرقام');
      return;
    }

    // Validate required fields
    String? phoneNumber = widget.phoneNumber;
    String? password = widget.password;
    String? phoneNumberOtpRequestId = widget.phoneNumberOtpRequestId;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      phoneNumber = await VerificationCache().getMobileNumber();
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showError('رقم الموبايل مطلوب');
      print('❌ OTP validation failed: phone number is missing');
      return;
    }

    if (password == null || password.isEmpty) {
      _showError('كلمة المرور مطلوبة');
      print('❌ OTP validation failed: password is missing');
      return;
    }

    if (phoneNumberOtpRequestId == null || phoneNumberOtpRequestId.isEmpty) {
      phoneNumberOtpRequestId = await VerificationCache().getPhoneNumberOtpRequestId();
      print('ℹ️ OTP request id from cache: $phoneNumberOtpRequestId');
    }

    if (phoneNumberOtpRequestId == null || phoneNumberOtpRequestId.isEmpty) {
      print(
        '⚠️ phoneNumberOtpRequestId missing; recovering via login (no OTP) request…',
      );
      phoneNumberOtpRequestId = await _recoverPhoneNumberOtpRequestIdFromLogin(
        phoneNumber: phoneNumber,
        password: password,
      );
      if (phoneNumberOtpRequestId == null || phoneNumberOtpRequestId.isEmpty) {
        _showError(
          'تعذر الحصول على معرف التحقق. أعد تسجيل الدخول أو تأكد من رد الخادم.',
        );
        print('❌ OTP validation failed: phoneNumberOtpRequestId still missing after login recovery');
        return;
      }
      print('✅ Recovered phoneNumberOtpRequestId from login response');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get device IMEI and location (same as original login)
      print('📱 Getting device information...');
      final deviceId = await DeviceInfoHelper.getDeviceId();
      final location = await DeviceInfoHelper.getCurrentLocation();

      print('📱 Device ID (IMEI): $deviceId');
      print('📍 Location: ${location['latitude']}, ${location['longitude']}');

      // Prepare request body with original login fields PLUS OTP fields
      final requestBody = jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
        'geoLocation': {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
        },
        'imei': deviceId,
        'phoneOtp': pinController.text,
        'phoneNumberOtpRequestId': phoneNumberOtpRequestId,
      });

      final headers = HttpHeadersHelper.getDefaultHeaders();

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 LOGIN API REQUEST (WITH OTP)');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlLogin');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: $requestBody');
      print('Phone Number: $phoneNumber');
      print('Password: ${'*' * password.length}');
      print('Phone Number OTP: ${pinController.text}');
      print('Phone Number OTP Request ID: $phoneNumberOtpRequestId');
      print('IMEI: $deviceId');
      print('GeoLocation: ${location['latitude']}, ${location['longitude']}');
      print('═══════════════════════════════════════════════════════');
      print('');

      http.Response response;
      try {
        response = await SdkHttpClient
            .post(
          Uri.parse(_apiUrlLogin),
          headers: headers,
          body: requestBody,
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout - Server may not be running or not accessible');
          },
        );
      } on SocketException catch (e) {
        print('');
        print('═══════════════════════════════════════════════════════');
        print('❌ CONNECTION ERROR - SocketException');
        print('═══════════════════════════════════════════════════════');
        print('Error: ${e.message}');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 LOGIN API RESPONSE (WITH OTP)');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.statusCode == 200) {
        try {
          if (response.body.isEmpty) {
            _showError('استجابة فارغة من الخادم');
            return;
          }

          final decoded = jsonDecode(response.body);
          if (decoded is! Map) {
            _showError('استجابة غير صالحة من الخادم');
            return;
          }
          final responseBody = Map<String, dynamic>.from(decoded as Map);

          final loginResponse = LoginResponse.fromJson(responseBody);
          print('✅ Login response parsed successfully');

          // Check if login was successful
          if (loginResponse.isSuccess && loginResponse.data != null) {
            // Success - close dialog and initialize VLens SDK
            if (!mounted) return;
            Navigator.of(context).pop();
            final navigationContext = widget.parentContext ?? context;
            if (navigationContext.mounted) {
              _initializeVLensSDK(
                  navigationContext, loginResponse.data!);
            }
          } else {
            // Login failed - show error
            final errorMessage = loginResponse.message ??
                loginResponse.errorMessage ??
                loginResponse.errorCode ??
                'فشل في تسجيل الدخول';
            _showError(errorMessage);
          }
        } catch (e, stackTrace) {
          print('');
          print('═══════════════════════════════════════════════════════');
          print('❌ ERROR PARSING LOGIN RESPONSE');
          print('═══════════════════════════════════════════════════════');
          print('Error: $e');
          print('Stack Trace: $stackTrace');
          print('Response Body: ${response.body}');
          print('═══════════════════════════════════════════════════════');
          print('');
          _showError('فشل في معالجة الاستجابة من الخادم');
        }
      } else {
        // Status code is NOT 200 - show error
        String errorMessage = 'فشل في تسجيل الدخول';
        print('⚠️ Non-200 response received in OTP verify login flow');
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ??
                errorBody['Message'] ??
                errorBody['error'] ??
                errorBody['Error'] ??
                errorBody['errorMessage'] ??
                errorBody['ErrorMessage'] ??
                errorBody['error_message'] ??
                errorBody['data']?['message'] ??
                errorBody['data']?['error'] ??
                'فشل في تسجيل الدخول';
            print('⚠️ Parsed non-200 error body: $errorBody');
          } else {
            switch (response.statusCode) {
              case 400:
                errorMessage = 'طلب غير صالح';
                break;
              case 401:
                errorMessage = 'غير مصرح - يرجى التحقق من بيانات الدخول';
                break;
              case 403:
                errorMessage = 'غير مصرح بالوصول';
                break;
              case 500:
                errorMessage = 'خطأ في الخادم';
                break;
              default:
                errorMessage = 'فشل في تسجيل الدخول (رمز الخطأ: ${response.statusCode})';
            }
          }
        } catch (e) {
          print('⚠️ Error parsing error response: $e');
          print('⚠️ Raw non-200 body (unparsed): ${response.body}');
        }

        print('❌ OTP login failed. Final error message: $errorMessage');
        _showError(errorMessage);
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      String userFriendlyMessage;

      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('connection refused')) {
        userFriendlyMessage = 'لا يمكن الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت';
      } else if (errorMessage.contains('timeout')) {
        userFriendlyMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
      } else {
        userFriendlyMessage = 'حدث خطأ أثناء التحقق. يرجى المحاولة مرة أخرى';
      }

      print('❌ OTP verify caught exception type: ${e.runtimeType}');
      print('❌ OTP verify exception details: $e');
      print('❌ OTP verify user-facing error: $userFriendlyMessage');
      _showError(userFriendlyMessage);
    } finally {
      print('═══════════════════════════════════════════════════════');
      print('🔐 VERIFY USER OTP END');
      print('═══════════════════════════════════════════════════════');
      print('');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Same as initial login body (no OTP) — server should return `phoneNumberOtpRequestId`
  /// when phone confirmation is required. Avoids `phone/send-otp` (417 for existing users).
  Future<String?> _recoverPhoneNumberOtpRequestIdFromLogin({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final deviceId = await DeviceInfoHelper.getDeviceId();
      final location = await DeviceInfoHelper.getCurrentLocation();
      final requestBody = jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
        'geoLocation': {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
        },
        'imei': deviceId,
      });
      final headers = HttpHeadersHelper.getDefaultHeaders();

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 LOGIN RECOVERY (no OTP) — fetch phoneNumberOtpRequestId');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlLogin');
      print('Body: $requestBody');

      final response = await SdkHttpClient.post(
        Uri.parse(_apiUrlLogin),
        headers: headers,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final loginResponse = LoginResponse.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      final id = loginResponse.data?.phoneNumberOtpRequestId?.trim();
      final tx = loginResponse.data?.transactionId?.trim();
      if (id != null && id.isNotEmpty) {
        unawaited(
          VerificationCache().setVerificationData(
            phoneNumberOtpRequestId: id,
            transactionId: tx ?? '',
            mobileNumber: phoneNumber,
          ),
        );
      }
      return id;
    } catch (e) {
      print('❌ Login recovery failed: $e');
      return null;
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  void _initializeVLensSDK(
      BuildContext context, LoginResponseData loginResponseData) {
    // Configure VLens SDK
    final sdkConfig = SdkConfig(
      transactionId: loginResponseData.transactionId ?? '',
      isLivenessOnly: false,
      isNationalIdOnly: false,
      env: EnvironmentConfig(
        apiBaseUrl: "https://api.vlenseg.com",
        accessToken: (loginResponseData.accessToken?.trim().isNotEmpty == true)
            ? loginResponseData.accessToken!
            : (loginResponseData.encryptedAccessToken ?? ""),
        refreshToken: loginResponseData.refreshToken ?? "",
        apiKey: "j1m9DwIywPS1dPCkFUT2hM2IRr10921gq5PBzQID6xI",
        tenancyName: "tanmeyah-stg",
      ),
      defaultLocale: "ar", // Arabic locale
      colors: ColorsConfig(
        light: ColorConfig(
          accent: "#4E5A78",
          primary: "#397374",
          secondary: "#FF4081",
          background: "#FEFEFE",
          dark: "#000000",
          light: "#FFFFFF",
        ),
        dark: ColorConfig(
          accent: "#FFC107",
          primary: "#2196F3",
          secondary: "#FF4081",
          background: "#000000",
          dark: "#FFFFFF",
          light: "#000000",
        ),
      ),
      errorMessages: [
        ApiError(
          errorCode: 101,
          errorMessageEn: "Network error",
          errorMessageAr: "خطأ في الشبكة",
        ),
      ],
      onSuccess: (extractedData) {
        print("✅ VLens SDK success - verification completed");
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScene()),
          );
        }
      },
      onFailure: (errorCode, errorMsg) {
        print("❌ VLens SDK failure: [$errorCode] $errorMsg");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في التحقق: $errorMsg'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      getExtractedData: true,
    );

    // Initialize VLens SDK - callbacks are passed via sdkConfig.
    final vlensManager = VLensManager();
    vlensManager.init(context, sdkConfig);
  }

  @override
  Widget build(BuildContext context) {
    final isPinComplete = pinController.text.length == 6;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 471.0 : screenWidth - 28;

    // Extract last two digits from masked phone number
    String lastTwoDigits = '';
    if (widget.maskedPhoneNumber != null && widget.maskedPhoneNumber!.isNotEmpty) {
      final digits = widget.maskedPhoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length >= 2) {
        lastTwoDigits = digits.substring(digits.length - 2);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: keyboardHeight + 20,
            left: 14,
            right: 14,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Icon(
                            Icons.close,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: AppText(
                              "تأكيد رقم الموبايل",
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),
                    16.height,
                    AppText(
                      lastTwoDigits.isNotEmpty
                          ? "برجاء إدخال الكود المكون من ٦ ارقام الذي تم ارساله إلي هاتفك المحمول **$lastTwoDigits"
                          : "برجاء إدخال الكود المكون من ٦ ارقام الذي تم ارساله إلي هاتفك المحمول",
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      16.height,
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                8.width,
                                Expanded(
                                  child: AppText(
                                    'خطأ في الاتصال',
                                    color: AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                            8.height,
                            AppText(
                              _errorMessage!,
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ),
                      ),
                    ],
                    24.height,
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Pinput(
                        length: 6,
                        controller: pinController,
                        focusNode: pinFocusNode,
                        keyboardType: TextInputType.number,
                        defaultPinTheme: PinTheme(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(
                              color: AppColors.border1,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: TextStyle(
                            color: AppColors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: TextStyle(
                            color: AppColors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onCompleted: (pin) {
                          _verifyOTP();
                        },
                      ),
                    ),
                    24.height,
                    GestureDetector(
                      onTap: canResend ? () {
                        // TODO: Implement resend logic if needed
                        _showError('سيتم إضافة ميزة إعادة الإرسال قريباً');
                      } : null,
                      child: AppText(
                        canResend
                            ? "إرسال مرة أخرى"
                            : "إرسال مرة أخرى بعد $countdown ثواني",
                        color: canResend ? AppColors.primary : AppColors.gray,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    70.height,
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AppButton(
                          title: _isLoading ? "" : "تأكيد",
                          backgroundColor:
                              _isLoading ? AppColors.primary : null,
                          textColor: isPinComplete && !_isLoading
                              ? AppColors.white
                              : AppColors.gray,
                          onPressed: isPinComplete && !_isLoading
                              ? _verifyOTP
                              : null,
                        ),
                        if (_isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
