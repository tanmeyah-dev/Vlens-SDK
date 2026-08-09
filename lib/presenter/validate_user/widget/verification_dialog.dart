import 'package:core/components/button/app_button.dart';
import 'package:core/components/text/app_text.dart';
import 'package:core/extensions/widget_extension.dart';
import 'package:core/utils/ui.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../routes/route_path.dart';
import '../../../utils/sdk_http_client.dart';
import '../constants/api_urls.dart';
import '../utils/verification_success_dialog_helper.dart';
import '../model/step_verify_phone_response.dart';
import 'package:core/utils/cache/verification_cache.dart';

class PhoneVerificationDialog extends StatefulWidget {
  final String lastTwoDigits;
  final String? mobileNumber;
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final Function(String) onConfirm;
  final BuildContext? parentContext;

  const PhoneVerificationDialog({
    super.key,
    required this.lastTwoDigits,
    this.mobileNumber,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    required this.onConfirm,
    this.parentContext,
  });

  @override
  State<PhoneVerificationDialog> createState() =>
      _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  int countdown = 30;
  bool canResend = false;
  Timer? countdownTimer;
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  late String? _phoneNumberOtpRequestId;
  late String? _transactionId;

  /// Vlens Register/StepVerifyPhone — used for resend + validate.
  String get _apiUrlStepVerifyPhone => ApiUrls.getStepVerifyPhoneUrl();

  @override
  void initState() {
    super.initState();
    _phoneNumberOtpRequestId = widget.phoneNumberOtpRequestId;
    _transactionId = widget.transactionId;
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

  Future<void> _resendCode() async {
    // Validate required fields
    if (widget.mobileNumber == null || widget.mobileNumber!.isEmpty) {
      _showError('رقم الموبايل مطلوب');
      return;
    }

    // Disable resend button and show loading
    setState(() {
      canResend = false;
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
      countdown = 59; // Reset countdown to 59 seconds
    });

    // Cancel existing timer
    countdownTimer?.cancel();

    try {
      // Prepare request body - same as initial OTP request
      final requestBody = jsonEncode({
        'phoneNumber': widget.mobileNumber,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 RESEND OTP API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlStepVerifyPhone');
      print('Method: POST');
      print('Headers: ${HttpHeadersHelper.getDefaultHeaders()}');
      print('Body: $requestBody');
      print('Phone Number: ${widget.mobileNumber}');
      print('═══════════════════════════════════════════════════════');
      print('');

      // Make API call
      http.Response response;
      try {
        response = await SdkHttpClient.post(
          Uri.parse(_apiUrlStepVerifyPhone),
          headers: HttpHeadersHelper.getDefaultHeaders(),
          body: requestBody,
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
                'Request timeout - Server may not be running or not accessible');
          },
        );
      } on SocketException catch (e) {
        print('');
        print('═══════════════════════════════════════════════════════');
        print('❌ CONNECTION ERROR - SocketException');
        print('═══════════════════════════════════════════════════════');
        print('Error: ${e.message}');
        print('URL Attempted: $_apiUrlStepVerifyPhone');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlStepVerifyPhone');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 RESEND OTP API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (mounted) {
        if (response.statusCode == 200) {
          try {
            if (response.body.isEmpty) {
              print('⚠️ Response body is empty');
              _showError('استجابة فارغة من الخادم');
              return;
            }

            final responseBody = jsonDecode(response.body);
            print('✅ JSON decoded successfully');
            print('📋 Response body: $responseBody');

            // Parse response using StepVerifyPhoneResponse model
            final stepVerifyPhoneResponse = StepVerifyPhoneResponse.fromJson(
              responseBody is Map<String, dynamic>
                  ? responseBody
                  : <String, dynamic>{},
            );

            print('');
            print('═══════════════════════════════════════════════════════');
            print('📊 RESEND OTP RESPONSE MODEL');
            print('═══════════════════════════════════════════════════════');
            print('Success: ${stepVerifyPhoneResponse.success}');
            print(
                'PhoneNumberOtpRequestId: ${stepVerifyPhoneResponse.phoneNumberOtpRequestId ?? "N/A"}');
            print(
                'TransactionId: ${stepVerifyPhoneResponse.transactionId ?? "N/A"}');
            print('═══════════════════════════════════════════════════════');
            print('');

            // Check for error_message first
            String? errorMessage =
                stepVerifyPhoneResponse.errorMessage?.trim() ??
                    stepVerifyPhoneResponse.errorDescriptions?.trim();

            if (errorMessage != null && errorMessage.isNotEmpty) {
              print(
                  '❌ Error message detected in resend response: $errorMessage');
              _showError(errorMessage);
              return;
            }

            // Check if we have the required IDs
            if (stepVerifyPhoneResponse.phoneNumberOtpRequestId != null &&
                stepVerifyPhoneResponse.phoneNumberOtpRequestId!.isNotEmpty) {
              _phoneNumberOtpRequestId =
                  stepVerifyPhoneResponse.phoneNumberOtpRequestId;
              _transactionId = stepVerifyPhoneResponse.transactionId ??
                  _transactionId ??
                  _phoneNumberOtpRequestId;

              // Save updated phoneNumberOtpRequestId and transactionId to cache
              await VerificationCache().setVerificationData(
                phoneNumberOtpRequestId: _phoneNumberOtpRequestId!,
                transactionId: _transactionId!,
                mobileNumber: widget.mobileNumber ?? '',
              );

              print('💾 Updated verification data in cache:');
              print(
                  '💾 phoneNumberOtpRequestId: $_phoneNumberOtpRequestId');
              print('💾 transactionId: $_transactionId');

              // Clear PIN input
              pinController.clear();

              // Start countdown timer
              countdownTimer =
                  Timer.periodic(const Duration(seconds: 1), (timer) {
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

              setState(() {
                _isLoading = false;
                canResend = false; // Keep disabled until countdown finishes
              });

              print('✅ OTP resent successfully');
            } else {
              print('❌ Resend OTP API response missing required fields');
              _showError('فشل في إعادة إرسال كود التحقق');
            }
          } catch (e, stackTrace) {
            print('');
            print('═══════════════════════════════════════════════════════');
            print('❌ ERROR PARSING RESEND OTP RESPONSE');
            print('═══════════════════════════════════════════════════════');
            print('Error: $e');
            print('Stack Trace: $stackTrace');
            print('Response Body: ${response.body}');
            print('═══════════════════════════════════════════════════════');
            print('');

            _showError('فشل في معالجة الاستجابة من الخادم');
          }
        } else {
          // Error response - extract error message
          String? errorMessage;

          try {
            if (response.body.isNotEmpty) {
              final errorBody = jsonDecode(response.body);

              // Helper function to safely extract string value
              String? getStringValue(String key) {
                final value = errorBody[key];
                if (value == null) return null;
                final str = value.toString().trim();
                return str.isEmpty ? null : str;
              }

              if (errorBody is Map<String, dynamic>) {
                // Check top-level fields first
                errorMessage = getStringValue('error_message') ??
                    getStringValue('errorMessage') ??
                    getStringValue('message') ??
                    getStringValue('error');

                // If not found, check nested data object
                if ((errorMessage == null || errorMessage.isEmpty) &&
                    errorBody['data'] != null) {
                  final data = errorBody['data'];
                  if (data is Map<String, dynamic>) {
                    String? getDataStringValue(String key) {
                      final value = data[key];
                      if (value == null) return null;
                      final str = value.toString().trim();
                      return str.isEmpty ? null : str;
                    }

                    errorMessage = getDataStringValue('error_message') ??
                        getDataStringValue('errorMessage') ??
                        getDataStringValue('message') ??
                        getDataStringValue('error');
                  }
                }
              }
            }
          } catch (e) {
            print('⚠️ Error parsing error response: $e');
          }

          // Only use default error message if no error message found in response
          if (errorMessage == null || errorMessage.isEmpty) {
            errorMessage = _getDefaultErrorMessage(response.statusCode);
          }

          print('❌ Resend OTP failed with status code: ${response.statusCode}');
          print('❌ Error message: $errorMessage');

          _showError(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        String userFriendlyMessage;

        if (errorMessage.contains('SocketException') ||
            errorMessage.contains('connection refused') ||
            errorMessage.contains('Connection refused') ||
            errorMessage.contains('SocketConnection') ||
            errorMessage.contains('Failed host lookup')) {
          userFriendlyMessage = 'لا يمكن الاتصال بالخادم.\n\n'
              'يرجى التحقق من:\n'
              '• الاتصال بالإنترنت\n'
              '• أن الخادم متاح\n'
              '• المحاولة مرة أخرى';
        } else if (errorMessage.contains('timeout') ||
            errorMessage.contains('Timeout')) {
          userFriendlyMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
        } else if (errorMessage.contains('Certificate') ||
            errorMessage.contains('SSL') ||
            errorMessage.contains('TLS')) {
          userFriendlyMessage = 'خطأ في شهادة الاتصال الآمن';
        } else {
          userFriendlyMessage =
              'حدث خطأ أثناء إعادة إرسال كود التحقق. يرجى المحاولة مرة أخرى';
        }

        print('❌ Error resending OTP: $errorMessage');
        print('❌ User-friendly message: $userFriendlyMessage');

        _showError(userFriendlyMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyPhoneNumber() async {
    // Validate required fields
    if (widget.mobileNumber == null || widget.mobileNumber!.isEmpty) {
      _showError('رقم الموبايل مطلوب');
      return;
    }

    if (pinController.text.length != 6) {
      _showError('يرجى إدخال الكود المكون من ٦ أرقام');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      final phoneOtpRequestId = _phoneNumberOtpRequestId?.trim();
      if (phoneOtpRequestId == null || phoneOtpRequestId.isEmpty) {
        _showError(
          'معرف التحقق من الهاتف غير موجود. أعد إرسال كود التحقق ثم حاول مرة أخرى.',
        );
        return;
      }

      // Vlens StepVerifyPhone validate contract:
      // phoneNumber + phoneNumberOtpRequestId + phoneNumberOtp
      final requestPayload = <String, dynamic>{
        'phoneNumber': widget.mobileNumber,
        'phoneNumberOtpRequestId': phoneOtpRequestId,
        'phoneNumberOtp': pinController.text,
      };
      final requestBody = jsonEncode(requestPayload);

      final headers = HttpHeadersHelper.getDefaultHeaders();

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 STEP VERIFY PHONE API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlStepVerifyPhone');
      print('Method: POST');
      print('Headers: $headers');
      print('ApiKey: ${headers['ApiKey']}');
      print('Content-Type: ${headers['Content-Type']}');
      print('Body: $requestBody');
      print('Phone Number: ${widget.mobileNumber}');
      print('Phone Number OTP: ${pinController.text}');
      print('═══════════════════════════════════════════════════════');
      print('');

      // Make API call with better error handling
      http.Response response;
      try {
        response = await SdkHttpClient.post(
          Uri.parse(_apiUrlStepVerifyPhone),
          headers: HttpHeadersHelper.getDefaultHeaders(),
          body: requestBody,
        )
            .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
                'Request timeout - Server may not be running or not accessible');
          },
        );
      } on SocketException catch (e) {
        // Connection error
        print('');
        print('═══════════════════════════════════════════════════════');
        print('❌ CONNECTION ERROR - SocketException');
        print('═══════════════════════════════════════════════════════');
        print('Error: ${e.message}');
        print('Address: ${e.address}');
        print('Port: ${e.port}');
        print('URL Attempted: $_apiUrlStepVerifyPhone');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlStepVerifyPhone');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 VERIFY PHONE API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          // Parse response using StepVerifyPhoneResponse model
          try {
            print('🔍 Attempting to parse response body...');

            // Check if body is empty
            if (response.body.isEmpty) {
              print('⚠️ Response body is empty');
              _showError('استجابة فارغة من الخادم');
              return;
            }

            final responseBody = jsonDecode(response.body);
            print('✅ JSON decoded successfully');
            print('📋 Response body type: ${responseBody.runtimeType}');
            print('📋 Response body content: $responseBody');

            // Check for explicit error fields in raw response body first.
            // Do not treat generic `message` as an error when success=true.
            String? rawErrorMessage;
            bool? rawSuccess;
            if (responseBody is Map<String, dynamic>) {
              final rawSuccessValue = responseBody['success'];
              if (rawSuccessValue is bool) {
                rawSuccess = rawSuccessValue;
              } else if (rawSuccessValue != null) {
                rawSuccess = rawSuccessValue.toString().toLowerCase() == 'true';
              }

              // Helper function to safely extract string value
              String? getStringValue(String key) {
                final value = responseBody[key];
                if (value == null) return null;
                final str = value.toString().trim();
                return str.isEmpty ? null : str;
              }

              // Check top-level fields first
              rawErrorMessage = getStringValue('error_message') ??
                  getStringValue('errorMessage') ??
                  getStringValue('error');

              // If not found, check nested data object
              if ((rawErrorMessage == null || rawErrorMessage.isEmpty) &&
                  responseBody['data'] != null) {
                final data = responseBody['data'];
                if (data is Map<String, dynamic>) {
                  String? getDataStringValue(String key) {
                    final value = data[key];
                    if (value == null) return null;
                    final str = value.toString().trim();
                    return str.isEmpty ? null : str;
                  }

                  rawErrorMessage = getDataStringValue('error_message') ??
                      getDataStringValue('errorMessage') ??
                      getDataStringValue('error');
                }
              }
            }

            // Show explicit error only when API indicates failure.
            if (rawErrorMessage != null &&
                rawErrorMessage.isNotEmpty &&
                rawSuccess == false) {
              print(
                  '❌ Error message detected in raw response - Showing error and staying on verification dialog');
              print('❌ Error message from API: $rawErrorMessage');

              // Show the error message from API response
              _showError(rawErrorMessage);
              return; // Stop here, don't navigate
            }

            final stepVerifyPhoneResponse = StepVerifyPhoneResponse.fromJson(
              responseBody is Map<String, dynamic>
                  ? responseBody
                  : <String, dynamic>{},
            );

            print('✅ StepVerifyPhoneResponse model created successfully');

            print('');
            print('═══════════════════════════════════════════════════════');
            print('📊 STEP VERIFY PHONE RESPONSE MODEL');
            print('═══════════════════════════════════════════════════════');
            print('Code: ${stepVerifyPhoneResponse.code ?? "N/A"}');
            print('Message: ${stepVerifyPhoneResponse.message ?? "N/A"}');
            print('API Success: ${stepVerifyPhoneResponse.apiSuccess ?? "N/A"}');
            print('Success: ${stepVerifyPhoneResponse.success}');
            print(
                'PhoneNumberOtpRequestId: ${stepVerifyPhoneResponse.phoneNumberOtpRequestId ?? "N/A"}');
            print(
                'TransactionId: ${stepVerifyPhoneResponse.transactionId ?? "N/A"}');
            print('Error Code: ${stepVerifyPhoneResponse.errorCode ?? "N/A"}');
            print(
                'Error Message: ${stepVerifyPhoneResponse.errorMessage ?? "N/A"}');
            print('═══════════════════════════════════════════════════════');
            print('');

            // Check parsed dedicated error fields only.
            String? errorMessage =
                stepVerifyPhoneResponse.errorMessage?.trim() ??
                    stepVerifyPhoneResponse.errorDescriptions?.trim();

            // Verify endpoint is successful when API returns success=true.
            final isVerificationSuccessful = stepVerifyPhoneResponse.success;
            if (isVerificationSuccessful) {
              print(
                  '✅ StepVerifyPhone API successful - Navigating to username security code screen');
              // Use response values if available, otherwise fall back to widget values
              final finalPhoneNumberOtpRequestId =
                  stepVerifyPhoneResponse.phoneNumberOtpRequestId ??
                      _phoneNumberOtpRequestId ??
                      '';
              final finalTransactionId =
                  stepVerifyPhoneResponse.transactionId ??
                      _transactionId ??
                      '';

              if (finalPhoneNumberOtpRequestId.isEmpty) {
                print(
                  '❌ Phone OTP verified but phoneNumberOtpRequestId is missing',
                );
                _showError(
                  'تعذر حفظ معرف التحقق من الهاتف. يرجى إعادة إرسال كود التحقق والمحاولة مرة أخرى.',
                );
                return;
              }

              await VerificationCache().setVerificationData(
                phoneNumberOtpRequestId: finalPhoneNumberOtpRequestId,
                transactionId: finalTransactionId.isNotEmpty
                    ? finalTransactionId
                    : finalPhoneNumberOtpRequestId,
                mobileNumber: widget.mobileNumber ?? '',
              );
              print('💾 Saved to cache from StepVerifyPhone API:');
              print(
                  '💾 phoneNumberOtpRequestId: $finalPhoneNumberOtpRequestId');
              print('💾 transactionId: $finalTransactionId');

              // Success - close verification dialog and show success dialog
              Navigator.of(context).pop();
              final successContext = widget.parentContext ?? context;
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (successContext.mounted) {
                  print('✅ Showing verification success dialog');
                  VerificationSuccessDialogHelper.showVerificationSuccessDialog(
                    successContext,
                    onDismiss: () {
                      print(
                          '✅ Success dialog dismissed, onDismiss callback called');
                      widget.onConfirm(pinController.text);
                    },
                  );
                } else {
                  print('⚠️ Success context not mounted');
                }
              });
            } else {
              print('❌ StepVerifyPhone API verification failed');

              final defaultErrorMessage = errorMessage ??
                  stepVerifyPhoneResponse.message ??
                  'فشل في التحقق من رقم الموبايل. يرجى التحقق من الكود المدخل';
              _showError(defaultErrorMessage);
            }
          } catch (e, stackTrace) {
            print('');
            print('═══════════════════════════════════════════════════════');
            print('❌ ERROR PARSING STEP VERIFY PHONE RESPONSE');
            print('═══════════════════════════════════════════════════════');
            print('Error: $e');
            print('Error Type: ${e.runtimeType}');
            print('Stack Trace: $stackTrace');
            print('Response Status Code: ${response.statusCode}');
            print('Response Body: ${response.body}');
            print('Response Body Length: ${response.body.length}');
            print('═══════════════════════════════════════════════════════');
            print('');

            // Try to extract error message from response if parsing failed
            String errorMessage = 'فشل في معالجة الاستجابة من الخادم';
            try {
              if (response.body.isNotEmpty) {
                final errorBody = jsonDecode(response.body);
                errorMessage = errorBody['message'] ??
                    errorBody['error'] ??
                    errorBody['errorMessage'] ??
                    errorBody['error_message'] ??
                    errorBody['data']?['message'] ??
                    errorBody['data']?['error'] ??
                    errorMessage;
              }
            } catch (_) {
              // If we can't parse error, use default message
            }

            _showError(errorMessage);
          }
        } else {
          // Error response - show error message for any non-200 status code
          String? errorMessage;

          try {
            if (response.body.isNotEmpty) {
              final errorBody = jsonDecode(response.body);

              print('');
              print('═══════════════════════════════════════════════════════');
              print('📋 EXTRACTING ERROR MESSAGE FROM RESPONSE');
              print('═══════════════════════════════════════════════════════');
              print('Response Body: $errorBody');
              print('Response Body Type: ${errorBody.runtimeType}');

              // Try to extract error message from different possible response formats
              // Priority: error_message > errorMessage > message > error > data.message > data.error
              if (errorBody is Map<String, dynamic>) {
                // Helper function to safely extract string value
                String? getStringValue(String key) {
                  final value = errorBody[key];
                  if (value == null) return null;
                  final str = value.toString().trim();
                  return str.isEmpty ? null : str;
                }

                // Check top-level fields first
                errorMessage = getStringValue('error_message') ??
                    getStringValue('errorMessage') ??
                    getStringValue('message') ??
                    getStringValue('error');

                // If not found, check nested data object
                if ((errorMessage == null || errorMessage.isEmpty) &&
                    errorBody['data'] != null) {
                  final data = errorBody['data'];
                  if (data is Map<String, dynamic>) {
                    String? getDataStringValue(String key) {
                      final value = data[key];
                      if (value == null) return null;
                      final str = value.toString().trim();
                      return str.isEmpty ? null : str;
                    }

                    errorMessage = getDataStringValue('error_message') ??
                        getDataStringValue('errorMessage') ??
                        getDataStringValue('message') ??
                        getDataStringValue('error');
                  }
                }
              }

              print('Extracted Error Message: ${errorMessage ?? "N/A"}');
              print('═══════════════════════════════════════════════════════');
              print('');
            }
          } catch (e) {
            // If JSON parsing fails, log and continue to use default message
            print('⚠️ Error parsing error response: $e');
            print('⚠️ Response body: ${response.body}');
          }

          // Only use default error message if no error message found in response
          if (errorMessage == null || errorMessage.isEmpty) {
            errorMessage = _getDefaultErrorMessage(response.statusCode);
            print(
                '⚠️ No error message found in response, using default message');
          }

          print(
              '❌ Verification failed with status code: ${response.statusCode}');
          print('❌ Final error message to show: $errorMessage');

          _showError(errorMessage);
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        print('');
        print('═══════════════════════════════════════════════════════');
        print('❌ EXCEPTION IN VERIFY PHONE NUMBER');
        print('═══════════════════════════════════════════════════════');
        print('Error: $e');
        print('Error Type: ${e.runtimeType}');
        print('Stack Trace: $stackTrace');
        print('═══════════════════════════════════════════════════════');
        print('');

        // Provide user-friendly error messages
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        String userFriendlyMessage;

        if (errorMessage.contains('SocketException') ||
            errorMessage.contains('connection refused') ||
            errorMessage.contains('Connection refused') ||
            errorMessage.contains('SocketConnection') ||
            errorMessage.contains('Failed host lookup')) {
          // Connection error - provide user-friendly message
          userFriendlyMessage = 'لا يمكن الاتصال بالخادم.\n\n'
              'يرجى التحقق من:\n'
              '• الاتصال بالإنترنت\n'
              '• أن الخادم متاح\n'
              '• المحاولة مرة أخرى';
        } else if (errorMessage.contains('timeout') ||
            errorMessage.contains('Timeout')) {
          userFriendlyMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
        } else if (errorMessage.contains('Certificate') ||
            errorMessage.contains('SSL') ||
            errorMessage.contains('TLS')) {
          userFriendlyMessage = 'خطأ في شهادة الاتصال الآمن';
        } else {
          // For other errors, show a generic message without technical details
          userFriendlyMessage = 'حدث خطأ أثناء التحقق. يرجى المحاولة مرة أخرى';
        }

        print('❌ Verification error: $errorMessage');
        print('❌ User-friendly message: $userFriendlyMessage');

        _showError(userFriendlyMessage);
      }
    }
  }

  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'طلب غير صحيح. يرجى التحقق من البيانات المدخلة';
      case 401:
        return 'غير مصرح. يرجى المحاولة مرة أخرى';
      case 403:
        return 'غير مسموح. يرجى التحقق من الصلاحيات';
      case 404:
        return 'الخدمة غير موجودة';
      case 408:
        return 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى';
      case 409:
        return 'الكود المدخل غير صحيح أو منتهي الصلاحية';
      case 429:
        return 'تم تجاوز عدد المحاولات المسموح بها. يرجى المحاولة لاحقاً';
      case 500:
        return 'خطأ في الخادم. يرجى المحاولة لاحقاً';
      case 502:
      case 503:
      case 504:
        return 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً';
      default:
        return 'فشل التحقق من رقم الموبايل. يرجى المحاولة مرة أخرى';
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
      // Clear error message after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPinComplete = pinController.text.length == 6;
    // Get keyboard height to position dialog above it
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive width
    final dialogWidth = screenWidth > 600 ? 471.0 : screenWidth - 28;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          // Add padding equal to keyboard height to position dialog above keyboard
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
                    // Instructions
                    AppText(
                      "برجاء إدخال الكود المكون من ٦ ارقام الذي تم ارساله إلي هاتفك المحمول **${widget.lastTwoDigits}",
                      color: AppColors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      textAlign: TextAlign.center,
                    ),
                    // Error message
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
                    // PIN Input - LTR for number input
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
                          // Automatically verify when PIN is complete
                          _verifyPhoneNumber();
                        },
                      ),
                    ),
                    24.height,
                    // Resend option
                    GestureDetector(
                      onTap: canResend ? _resendCode : null,
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
                    // Confirm button
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
                              ? () {
                                  _verifyPhoneNumber();
                                }
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
