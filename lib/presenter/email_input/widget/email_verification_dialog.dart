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
import '../model/step_verify_email_response.dart';
import 'package:core/utils/cache/verification_cache.dart';
import '../utils/email_verification_success_dialog_helper.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final String? emailOtpRequestId;
  final String? transactionId;
  final Function(String) onConfirm;
  final BuildContext? parentContext;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    this.emailOtpRequestId,
    this.transactionId,
    required this.onConfirm,
    this.parentContext,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  int countdown = 30;
  bool canResend = false;
  Timer? countdownTimer;
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  
  /// Production API URL for verify email
  static const String _apiUrlVerify = 'https://api.vlenseg.com/api/DigitalIdentity/Register/StepVerifyEmail';

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

  String _maskEmail(String email) {
    if (email.isEmpty) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final localPart = parts[0];
    final domain = parts[1];
    
    if (localPart.length <= 2) {
      return '${localPart[0]}*@$domain';
    }
    
    final maskedLocal = '${localPart[0]}${'*' * (localPart.length - 1)}';
    return '$maskedLocal@$domain';
  }

  Future<void> _resendCode() async {
    // Validate required fields
    if (widget.email.isEmpty) {
      _showError('الإيميل مطلوب');
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
        'email': widget.email,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 RESEND EMAIL OTP API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlVerify');
      print('Method: POST');
      print('Headers: ${HttpHeadersHelper.getDefaultHeaders()}');
      print('Body: $requestBody');
      print('Email: ${widget.email}');
      print('═══════════════════════════════════════════════════════');
      print('');

      // Make API call
      http.Response response;
      try {
        response = await http.post(
          Uri.parse(_apiUrlVerify),
          headers: HttpHeadersHelper.getDefaultHeaders(),
          body: requestBody,
        ).timeout(
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
        print('URL Attempted: $_apiUrlVerify');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlVerify');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 RESEND EMAIL OTP API RESPONSE');
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

            // Parse response using StepVerifyEmailResponse model
            final stepVerifyEmailResponse = StepVerifyEmailResponse.fromJson(
              responseBody is Map<String, dynamic>
                  ? responseBody
                  : <String, dynamic>{},
            );

            print('');
            print('═══════════════════════════════════════════════════════');
            print('📊 RESEND EMAIL OTP RESPONSE MODEL');
            print('═══════════════════════════════════════════════════════');
            print('Success: ${stepVerifyEmailResponse.success}');
            print('EmailOtpRequestId: ${stepVerifyEmailResponse.emailOtpRequestId ?? "N/A"}');
            print('TransactionId: ${stepVerifyEmailResponse.transactionId ?? "N/A"}');
            print('═══════════════════════════════════════════════════════');
            print('');

            // Check for error_message first
            String? errorMessage = stepVerifyEmailResponse.errorMessage?.trim() ??
                stepVerifyEmailResponse.errorDescriptions?.trim();

            if (errorMessage != null && errorMessage.isNotEmpty) {
              print('❌ Error message detected in resend response: $errorMessage');
              _showError(errorMessage);
              return;
            }

            // Check if we have the required IDs
            if (stepVerifyEmailResponse.emailOtpRequestId != null &&
                stepVerifyEmailResponse.emailOtpRequestId!.isNotEmpty &&
                stepVerifyEmailResponse.transactionId != null &&
                stepVerifyEmailResponse.transactionId!.isNotEmpty) {
              // Save updated emailOtpRequestId and transactionId to cache
              await VerificationCache().setEmailVerificationData(
                emailOtpRequestId: stepVerifyEmailResponse.emailOtpRequestId!,
                transactionId: stepVerifyEmailResponse.transactionId!,
                email: widget.email,
              );

              print('💾 Updated verification data in cache:');
              print('💾 emailOtpRequestId: ${stepVerifyEmailResponse.emailOtpRequestId}');
              print('💾 transactionId: ${stepVerifyEmailResponse.transactionId}');

              // Clear PIN input
              pinController.clear();

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

              setState(() {
                _isLoading = false;
                canResend = false; // Keep disabled until countdown finishes
              });

              print('✅ Email OTP resent successfully');
            } else {
              print('❌ Resend Email OTP API response missing required fields');
              _showError('فشل في إعادة إرسال كود التحقق');
            }
          } catch (e, stackTrace) {
            print('');
            print('═══════════════════════════════════════════════════════');
            print('❌ ERROR PARSING RESEND EMAIL OTP RESPONSE');
            print('═══════════════════════════════════════════════════════');
            print('Error: $e');
            print('Error Type: ${e.runtimeType}');
            print('Stack Trace: $stackTrace');
            print('Response Status Code: ${response.statusCode}');
            print('Response Body: ${response.body}');
            print('═══════════════════════════════════════════════════════');
            print('');
            _showError('فشل في معالجة الاستجابة من الخادم');
          }
        } else {
          // Error response (non-200 status)
          print('❌ Resend Email OTP API failed with status code: ${response.statusCode}');
          print('Error Body: ${response.body}');
          
          try {
            // Check for invalid API key errors
            String errorBodyString = response.body.toLowerCase();
            bool isInvalidApiKey = response.statusCode == 401 || 
                response.statusCode == 403 ||
                errorBodyString.contains('invalid api key') ||
                errorBodyString.contains('invalid api') ||
                errorBodyString.contains('api key') ||
                errorBodyString.contains('unauthorized') ||
                errorBodyString.contains('forbidden');
            
            if (isInvalidApiKey) {
              print('🔑 Invalid API Key detected in Resend Email OTP');
              _showError('مفتاح API غير صالح');
              return;
            }
            
            final errorBody = jsonDecode(response.body);
            final errorResponse = StepVerifyEmailResponse.fromJson(
              errorBody is Map<String, dynamic> 
                  ? errorBody 
                  : <String, dynamic>{},
            );
            
            final errorMessage = errorResponse.errorMessage ?? 
                errorResponse.errorDescriptions ??
                'فشل في إرسال كود التحقق';
            _showError(errorMessage);
          } catch (e) {
            print('⚠️ Error parsing error response: $e');
            _showError('فشل في إرسال كود التحقق');
          }
        }
      }
    } catch (e) {
      // Reset loading state and flag
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Handle network or other errors with better error messages
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Provide more user-friendly error messages
      if (errorMessage.contains('SocketException') || 
          errorMessage.contains('connection refused') ||
          errorMessage.contains('Failed host lookup')) {
        errorMessage = 'لا يمكن الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت أو أن الخادم يعمل';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
      } else if (errorMessage.contains('Certificate') || errorMessage.contains('SSL')) {
        errorMessage = 'خطأ في شهادة الاتصال الآمن';
      } else {
        errorMessage = 'حدث خطأ أثناء إعادة إرسال كود التحقق: $errorMessage';
      }
      
      print('❌ Resend Email OTP error: ${e.toString()}');
      print('❌ User-friendly error: $errorMessage');
      _showError(errorMessage);
    }
  }

  Future<void> _verifyEmail() async {
    // Validate required fields
    if (widget.email.isEmpty) {
      _showError('الإيميل مطلوب');
      return;
    }

    if (pinController.text.length != 6) {
      _showError('يرجى إدخال الكود المكون من ٦ أرقام');
      return;
    }

    // Get emailOtpRequestId and transactionId from widget or cache
    String? emailOtpRequestId = widget.emailOtpRequestId;
    String? transactionId = widget.transactionId;
    
    // If not provided in widget, try to get from cache
    if (emailOtpRequestId == null || emailOtpRequestId.isEmpty) {
      emailOtpRequestId = await VerificationCache().getEmailOtpRequestId();
    } else {
    }
    
    if (transactionId == null || transactionId.isEmpty) {
      transactionId = await VerificationCache().getTransactionId();
    } else {
    }
    
    // Validate that we have the required IDs
    if (emailOtpRequestId == null || emailOtpRequestId.isEmpty) {
      _showError('emailOtpRequestId مطلوب');
      return;
    }
    
    if (transactionId == null || transactionId.isEmpty) {
      _showError('transactionId مطلوب');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      // Prepare request body with all required fields
      final requestBody = jsonEncode({
        'email': widget.email,
        'emailOtp': pinController.text,
        'emailOtpRequestId': emailOtpRequestId,
        'transactionId': transactionId,
      });

      final headers = HttpHeadersHelper.getDefaultHeaders();
      
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 STEP VERIFY EMAIL API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlVerify');
      print('Method: POST');
      print('Headers: $headers');
      print('ApiKey: ${headers['ApiKey']}');
      print('Content-Type: ${headers['Content-Type']}');
      print('Body: $requestBody');
      print('Email: ${widget.email}');
      print('Email OTP: ${pinController.text}');
      print('Email OTP Request ID: $emailOtpRequestId');
      print('Transaction ID: $transactionId');
      print('═══════════════════════════════════════════════════════');
      print('');

      // Make API call with better error handling
      http.Response response;
      try {
        response = await http.post(
          Uri.parse(_apiUrlVerify),
          headers: HttpHeadersHelper.getDefaultHeaders(),
          body: requestBody,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout - Server may not be running or not accessible');
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
        print('URL Attempted: $_apiUrlVerify');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlVerify');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 VERIFY EMAIL API RESPONSE');
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
          // Parse response
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
            
            // Check for error_message in raw response body first
            String? rawErrorMessage;
            if (responseBody is Map<String, dynamic>) {
              rawErrorMessage = responseBody['error_message']?.toString() ?? 
                                responseBody['errorMessage']?.toString() ??
                                responseBody['message']?.toString();
            }
            
            // If error_message exists, show it and stop navigation
            if (rawErrorMessage != null && rawErrorMessage.isNotEmpty) {
              print('❌ Error message detected in raw response - Showing error and staying on verification dialog');
              print('❌ Error message: $rawErrorMessage');
              
              // Show the error message from API response
              _showError(rawErrorMessage);
              return; // Stop here, don't navigate
            }
            
            final stepVerifyEmailResponse = StepVerifyEmailResponse.fromJson(
              responseBody is Map<String, dynamic> 
                  ? responseBody 
                  : <String, dynamic>{},
            );
            
            print('✅ StepVerifyEmailResponse model created successfully');

            print('');
            print('═══════════════════════════════════════════════════════');
            print('📊 STEP VERIFY EMAIL RESPONSE MODEL');
            print('═══════════════════════════════════════════════════════');
            print('Success: ${stepVerifyEmailResponse.success}');
            print('EmailOtpRequestId: ${stepVerifyEmailResponse.emailOtpRequestId ?? "N/A"}');
            print('TransactionId: ${stepVerifyEmailResponse.transactionId ?? "N/A"}');
            print('Error Code: ${stepVerifyEmailResponse.errorCode ?? "N/A"}');
            print('Error Message: ${stepVerifyEmailResponse.errorMessage ?? "N/A"}');
            print('═══════════════════════════════════════════════════════');
            print('');


            // Check for error_message in parsed model
            final errorMessage = stepVerifyEmailResponse.errorMessage ?? 
                stepVerifyEmailResponse.errorDescriptions;
            
            // If error_message exists, show it and stop navigation
            if (errorMessage != null && errorMessage.isNotEmpty) {
              print('❌ Error message detected in model - Showing error and staying on verification dialog');
              print('❌ Error message: $errorMessage');
              
              // Show the error message from API response
              _showError(errorMessage);
              return; // Stop here, don't navigate
            }

            // Check if response is successful
            if (stepVerifyEmailResponse.success) {
              print('✅ StepVerifyEmail API successful - Showing success dialog');
              
              // Use response values if available, otherwise fall back to widget values
              final finalEmailOtpRequestId = stepVerifyEmailResponse.emailOtpRequestId ?? 
                  widget.emailOtpRequestId ?? '';
              final finalTransactionId = stepVerifyEmailResponse.transactionId ?? 
                  widget.transactionId ?? '';
              
              // Save to cache if we have valid values
              if (finalEmailOtpRequestId.isNotEmpty && finalTransactionId.isNotEmpty) {
                await VerificationCache().setEmailVerificationData(
                  emailOtpRequestId: finalEmailOtpRequestId,
                  transactionId: finalTransactionId,
                  email: widget.email,
                );
                print('💾 Saved to cache from StepVerifyEmail API:');
                print('💾 emailOtpRequestId: $finalEmailOtpRequestId');
                print('💾 transactionId: $finalTransactionId');
                print('💾 email: ${widget.email}');
              }
              
              // Success - close verification dialog and show success dialog
              Navigator.of(context).pop();
              final successContext = widget.parentContext ?? context;
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (successContext.mounted) {
                  EmailVerificationSuccessDialogHelper.showEmailVerificationSuccessDialog(
                    successContext,
                    onDismiss: () {
                      // Callback after success dialog dismisses and navigates
                      widget.onConfirm(pinController.text);
                    },
                  );
                }
              });
            } else {
              // Response doesn't have required fields
              print('❌ StepVerifyEmail API response missing required fields');
              
              final defaultErrorMessage = errorMessage ?? 
                  stepVerifyEmailResponse.errorDescriptions ??
                  'فشل في التحقق من الإيميل. يرجى التحقق من الكود المدخل';
              _showError(defaultErrorMessage);
            }
          } catch (e, stackTrace) {
            print('');
            print('═══════════════════════════════════════════════════════');
            print('❌ ERROR PARSING STEP VERIFY EMAIL RESPONSE');
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
          String errorMessage = 'فشل التحقق من الإيميل';
          
          try {
            if (response.body.isNotEmpty) {
              final errorBody = jsonDecode(response.body);
              
              // Try to extract error message from different possible response formats
              errorMessage = errorBody['message'] ?? 
                            errorBody['error'] ?? 
                            errorBody['errorMessage'] ??
                            errorBody['data']?['message'] ??
                            errorBody['data']?['error'] ??
                            _getDefaultErrorMessage(response.statusCode);
            } else {
              errorMessage = _getDefaultErrorMessage(response.statusCode);
            }
          } catch (e) {
            // If JSON parsing fails, use default error message based on status code
            print('⚠️ Error parsing error response: $e');
            errorMessage = _getDefaultErrorMessage(response.statusCode);
          }
          
          print('❌ Verification failed with status code: ${response.statusCode}');
          print('❌ Error message: $errorMessage');
          
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
        print('❌ EXCEPTION IN VERIFY EMAIL');
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
        } else if (errorMessage.contains('timeout') || errorMessage.contains('Timeout')) {
          userFriendlyMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
        } else if (errorMessage.contains('Certificate') || errorMessage.contains('SSL') || errorMessage.contains('TLS')) {
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
        return 'فشل التحقق من الإيميل. يرجى المحاولة مرة أخرى';
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
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
    final maskedEmail = _maskEmail(widget.email);
    
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
                  // Title
                  AppText(
                    "تأكيد الإيميل الخاص بك",
                    color: AppColors.error,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  16.height,
                  // Instructions
                  AppText(
                    "برجاء إدخال الكود المكون من ٦ ارقام الذي تم ارساله إلي إيميلك",
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                  ),
                  8.height,
                  // Email address
                  AppText(
                    maskedEmail,
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                  ),
                  // Error message
                  if (_errorMessage != null) ...[
                    16.height,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        _verifyEmail();
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
                        backgroundColor: _isLoading ? AppColors.primary : null,
                        textColor: isPinComplete && !_isLoading ? AppColors.white : AppColors.gray,
                        onPressed: isPinComplete && !_isLoading
                            ? () {
                                _verifyEmail();
                              }
                            : null,
                      ),
                      if (_isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
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
