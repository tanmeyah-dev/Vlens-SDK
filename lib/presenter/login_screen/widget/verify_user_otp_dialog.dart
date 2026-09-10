import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/style/app_colors.dart';
import 'package:core/utils/ui.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_api_response.dart';
import '../../../utils/sdk_http_client.dart';
import '../../validate_user/constants/api_urls.dart';
import 'package:core/utils/cache/verification_cache.dart';
import '../utils/device_info_helper.dart';
import '../utils/vlens_sdk_launcher.dart';
import '../model/login_response.dart';
import '../../id_data/scene/id_data_screen.dart';
import 'package:tan_sdk/utils/extracted_data_log.dart';
import '../utils/request_documents_navigator.dart';

class VerifyUserOTPDialog extends StatefulWidget {
  final String? phoneNumber;
  final String? password;
  final String? maskedPhoneNumber;
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final BuildContext? parentContext;
  final String? vlenseStatus;

  const VerifyUserOTPDialog({
    super.key,
    this.phoneNumber,
    this.password,
    this.maskedPhoneNumber,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.parentContext,
    this.vlenseStatus,
  });

  @override
  State<VerifyUserOTPDialog> createState() => _VerifyUserOTPDialogState();
}

class _VerifyUserOTPDialogState extends State<VerifyUserOTPDialog> {
  static const int _countdownSeconds = 59;

  int countdown = _countdownSeconds;
  bool canResend = false;
  bool _isResending = false;
  Timer? countdownTimer;
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  String get _apiUrlLogin => ApiUrls.getLoginUrl();
  String get _apiUrlLoginVerifyOtp => ApiUrls.getLoginVerifyOtpUrl();

  @override
  void initState() {
    super.initState();
    _startCountdown(notify: false);

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

  void _startCountdown({bool notify = true}) {
    countdownTimer?.cancel();
    void apply() {
      countdown = _countdownSeconds;
      canResend = false;
    }

    if (notify && mounted) {
      setState(apply);
    } else {
      apply();
    }

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    });
  }

  Future<void> _onResendPressed() async {
    if (!canResend || _isResending || _isLoading) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final ok = await _resendOtpViaLoginApi();
      if (!mounted) return;
      if (ok) {
        pinController.clear();
        _startCountdown();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  /// Re-calls the same login API that originally triggered the OTP SMS.
  Future<bool> _resendOtpViaLoginApi() async {
    String? phoneNumber = widget.phoneNumber;
    String? password = widget.password;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      phoneNumber = await VerificationCache().getMobileNumber();
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showError('رقم الموبايل مطلوب');
      return false;
    }

    if (password == null || password.isEmpty) {
      _showError('كلمة المرور مطلوبة');
      return false;
    }

    try {
      final locationResult =
          await DeviceInfoHelper.obtainRequiredLocationForAuth();
      if (!locationResult.hasCoordinates) {
        _showError(locationResult.errorMessage);
        return false;
      }

      final deviceId = await DeviceInfoHelper.getDeviceId();
      final requestBody = jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
        'geoLocation': {
          'latitude': locationResult.latitude,
          'longitude': locationResult.longitude,
        },
        'imei': deviceId,
      });

      final headers = HttpHeadersHelper.getDefaultHeaders();

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 LOGIN API REQUEST (RESEND OTP)');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlLogin');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: $requestBody');
      print('═══════════════════════════════════════════════════════');
      print('');

      final response = await SdkHttpClient
          .post(
        Uri.parse(_apiUrlLogin),
        headers: headers,
        body: requestBody,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Request timeout - Server may not be running or not accessible');
        },
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 LOGIN API RESPONSE (RESEND OTP)');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (!mounted) return false;
      if (response.sdk.isUnauthorized) return false;

      final blockingError = response.sdk.blockingError(
        httpFallback: 'فشل إعادة إرسال الكود',
        businessFallback: 'فشل إعادة إرسال الكود',
      );
      if (blockingError != null) {
        _showError(blockingError);
        return false;
      }

      if (response.statusCode != 200) {
        final errorMessage = ApiErrorParser.extractMessage(
          response.body,
          fallbackMessage: 'فشل إعادة إرسال الكود',
        );
        _showError(errorMessage);
        return false;
      }

      if (response.body.isEmpty) {
        _showError('استجابة فارغة من الخادم');
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        _showError('استجابة غير صالحة من الخادم');
        return false;
      }

      final loginResponse =
          LoginResponse.fromJson(Map<String, dynamic>.from(decoded));
      if (!loginResponse.isSuccess) {
        final errorMessage = loginResponse.message ??
            loginResponse.errorMessage ??
            'فشل إعادة إرسال الكود';
        _showError(errorMessage);
        return false;
      }

      final data = loginResponse.data;
      final otpReqId = data?.phoneNumberOtpRequestId;
      final txId = data?.transactionId;
      if (otpReqId != null &&
          otpReqId.isNotEmpty &&
          txId != null &&
          txId.isNotEmpty) {
        await VerificationCache().setVerificationData(
          phoneNumberOtpRequestId: otpReqId,
          transactionId: txId,
          mobileNumber: phoneNumber,
        );
      }

      return true;
    } on SocketException {
      _showError('لا يمكن الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت');
      return false;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('timeout')) {
        _showError('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى');
      } else {
        _showError('حدث خطأ أثناء إعادة إرسال الكود. يرجى المحاولة مرة أخرى');
      }
      return false;
    }
  }

  Future<void> _verifyOTP() async {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔐 VERIFY USER OTP START');
    print('═══════════════════════════════════════════════════════');
    print('OTP Length: ${pinController.text.length}');
    print('Has Phone (widget): ${widget.phoneNumber?.isNotEmpty == true}');
    print('Has Password (widget): ${widget.password?.isNotEmpty == true}');
    print('═══════════════════════════════════════════════════════');
    print('');

    if (pinController.text.length != 6) {
      print('❌ OTP validation failed: OTP must be 6 digits');
      _showError('يرجى إدخال الكود المكون من ٦ أرقام');
      return;
    }

    String? phoneNumber = widget.phoneNumber;
    String? password = widget.password;

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

      // Prepare request body with original login fields PLUS OTP
      final requestBody = jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
        'geoLocation': {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
        },
        'imei': deviceId,
        'phoneNumberOtp': pinController.text,
      });

      final headers = HttpHeadersHelper.getDefaultHeaders();

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 LOGIN API REQUEST (WITH OTP)');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlLoginVerifyOtp');
      print('Method: POST');
      print('Headers: $headers');
      print('Body: $requestBody');
      print('Phone Number: $phoneNumber');
      print('Password: ${'*' * password.length}');
      print('phoneNumberOtp: ${pinController.text}');
      print('IMEI: $deviceId');
      print('GeoLocation: ${location['latitude']}, ${location['longitude']}');
      print('═══════════════════════════════════════════════════════');
      print('');

      http.Response response;
      try {
        response = await SdkHttpClient
            .post(
          Uri.parse(_apiUrlLoginVerifyOtp),
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

      if (mounted) {
        if (response.sdk.isUnauthorized) return;
        final blockingError = response.sdk.blockingError(
          httpFallback: 'فشل في تسجيل الدخول',
          businessFallback: 'فشل في تسجيل الدخول',
        );
        if (blockingError != null) {
          _showError(blockingError);
          return;
        }
      }

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
          final responseBody = Map<String, dynamic>.from(decoded);
          final rawData = responseBody['data'];
          if (rawData is Map) {
            print('🔍 RAW verify-otp data.accessToken is null: ${rawData['accessToken'] == null}');
            print('🔍 RAW verify-otp data.refreshToken is null: ${rawData['refreshToken'] == null}');
            print('🔍 RAW verify-otp data.encryptedAccessToken is null: ${rawData['encryptedAccessToken'] == null}');
            print('🔍 RAW verify-otp data keys: ${rawData.keys.toList()}');
          } else {
            print('🔍 RAW verify-otp data is not Map: ${rawData.runtimeType}');
          }

          final loginResponse = LoginResponse.fromJson(responseBody);
          print('✅ Login response parsed successfully');
          final parsed = loginResponse.data;
          print('🔎 verify-otp response keys: ${responseBody.keys.toList()}');
          if (responseBody['data'] is Map) {
            print('🔎 verify-otp response data keys: ${(responseBody['data'] as Map).keys.toList()}');
          }
          print('🔑 verify-otp fields used for login/session:');
          print(' - accessToken exists: ${parsed?.accessToken?.trim().isNotEmpty == true}');
          print(' - refreshToken exists: ${parsed?.refreshToken?.trim().isNotEmpty == true}');
          print(' - encryptedAccessToken exists: ${parsed?.encryptedAccessToken?.trim().isNotEmpty == true}');
          print(' - transactionId: ${parsed?.transactionId}');
          print(' - phoneNumberOtpRequestId: ${parsed?.phoneNumberOtpRequestId}');
          print(' - isPhoneNumberConfirmationRequired: ${parsed?.isPhoneNumberConfirmationRequired}');
          print(' - isDigitalIdentityVerified: ${parsed?.isDigitalIdentityVerified}');

          // Check if login was successful
          if (loginResponse.isSuccess && loginResponse.data != null) {
            // Success - close dialog and initialize VLens SDK
            if (!mounted) return;
            Navigator.of(context).pop();
            final navigationContext = widget.parentContext ?? context;
            if (navigationContext.mounted) {
              final loginData = loginResponse.data!;
              await VerificationCache().setLoginSession(
                accessToken: loginData.accessToken,
                refreshToken: loginData.refreshToken,
                encryptedAccessToken: loginData.encryptedAccessToken,
                transactionId: loginData.transactionId,
                userName: loginData.userName,
                userFullName: loginData.userFullName,
                nationalId: loginData.nationalId,
              );
              final resolvedMobileNumber =
                  (loginData.userName ?? '').trim().isNotEmpty
                      ? loginData.userName!.trim()
                      : (widget.phoneNumber ?? '').trim();
              if (resolvedMobileNumber.isNotEmpty) {
                await VerificationCache().setMobileNumber(resolvedMobileNumber);
              }
              await _cacheLoginResponseData(loginData);
              // Wait until the OTP dialog pop finishes unlocking the navigator.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!navigationContext.mounted) return;
                if (RequestDocumentsNavigator.isStatus200(widget.vlenseStatus)) {
                  unawaited(
                    RequestDocumentsNavigator.openAfterLogin(navigationContext),
                  );
                  return;
                }
                if (loginData.isDigitalIdentityVerified == true) {
                  unawaited(_openIdDataScreenAfterLogin(navigationContext));
                  return;
                }
                _initializeVLensSDK(navigationContext, loginData);
              });
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
        final apiErrorMessage = ApiErrorParser.extractMessage(
          response.body,
          fallbackMessage: errorMessage,
        );
        if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
          errorMessage = apiErrorMessage;
        }
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
            if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
              errorMessage = apiErrorMessage;
            }
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
          if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
            errorMessage = apiErrorMessage;
          }
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
    final launched = VlensSdkLauncher.launch(
      context: context,
      loginResponseData: loginResponseData,
      source: 'verify_user_otp_dialog',
      onSuccess: (extractedData) {
        logExtractedDataAfterLogin(extractedData, context: 'after login');
        final navigationContext = widget.parentContext ?? context;
        if (!navigationContext.mounted) return;
        unawaited(_cacheVlensSuccessPayload(extractedData));
        Navigator.of(navigationContext).push(
          MaterialPageRoute(
            builder: (_) => IdDataScreen(extractedData: extractedData),
          ),
        );
      },
      onFailure: (errorCode, errorMsg) {
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
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(VlensSdkLauncher.missingMessage(loginResponseData)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _cacheVlensExtractedData(dynamic extractedData) async {
    try {
      final normalized = jsonDecode(jsonEncode(extractedData));
      await VerificationCache().setVlensExtractedData(normalized);
    } catch (_) {
      // Best effort cache only.
    }
  }

  Future<void> _cacheVlensSuccessPayload(dynamic extractedData) async {
    await _cacheVlensExtractedData(extractedData);
    try {
      final normalized = jsonDecode(jsonEncode(extractedData));
      await VerificationCache().setVlensTraceResponseBody(normalized);
    } catch (_) {
      // Best effort cache only.
    }
  }

  Future<void> _cacheLoginResponseData(dynamic loginResponseData) async {
    try {
      final normalized = jsonDecode(jsonEncode(loginResponseData));
      await VerificationCache().setLoginResponseData(normalized);
    } catch (e) {
      print('⚠️ Failed to cache login response data (verify otp): $e');
    }
  }

  /// Verified identity: open [IdDataScreen] so it can GET `/vlens-data` and fill the table.
  Future<void> _openIdDataScreenAfterLogin(BuildContext navigationContext) async {
    // Avoid !_debugLocked when the previous route transition is still active.
    await WidgetsBinding.instance.endOfFrame;
    if (!navigationContext.mounted) return;
    Navigator.of(navigationContext).push(
      MaterialPageRoute<void>(
        builder: (_) => const IdDataScreen(loadFromApi: true),
      ),
    );
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
                      onTap: (canResend && !_isResending && !_isLoading)
                          ? _onResendPressed
                          : null,
                      child: AppText(
                        _isResending
                            ? 'جاري الإرسال...'
                            : (canResend
                                ? 'إرسال مرة أخرى'
                                : 'إرسال مرة أخرى بعد $countdown ثواني'),
                        color: (canResend && !_isResending && !_isLoading)
                            ? AppColors.primary
                            : AppColors.gray,
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
