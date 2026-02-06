import 'dart:async';
import 'dart:convert';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/bases/states/general_state/general_render_state.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:http/http.dart' as http;
import '../event/mobile_number_event.dart';
import '../model/mobile_number_model.dart';
import '../model/mobile_number_response.dart';
import '../model/step_verify_phone_response.dart';
import '../state/mobile_number_state.dart';

class MobileNumberBloc extends BaseBloc {
  final MobileNumberModel _mobileNumberModel;
  static const String _apiUrlCheck =
      'https://api.vlenseg.com/api/DigitalIdentity/CheckExistenceOfEmailOrPhone';
  static const String _apiUrlStepVerifyPhone =
      'https://api.vlenseg.com/api/DigitalIdentity/Register/StepVerifyPhone';
  
  // Flag to prevent duplicate API calls
  bool _isRequestInProgress = false;
  int _requestCounter = 0;
  Completer<void>? _currentRequestCompleter;

  MobileNumberBloc(this._mobileNumberModel)
      : super(initialState: InitScreen(_mobileNumberModel)) {
    on<EnableSaveButtonEvent>(_onEnableSaveButtonEvent);
    on<SaveMobileNumberEvent>(_onSaveMobileNumberEvent);
    on<UpdateLoadingStateEvent>(_onUpdateLoadingStateEvent);
  }

  _onEnableSaveButtonEvent(EnableSaveButtonEvent event, emit) {
    _mobileNumberModel.isSaveButtonDisabled = !event.isEnabled;
    emit(UpdateMobileNumberUI(_mobileNumberModel));
  }

  _onUpdateLoadingStateEvent(UpdateLoadingStateEvent event, emit) {
    _mobileNumberModel.isLoading = event.isLoading;
    emit(UpdateMobileNumberUI(_mobileNumberModel));
  }

  _onSaveMobileNumberEvent(SaveMobileNumberEvent event, emit) async {
    // CRITICAL: Check flag FIRST - if already in progress, wait for it to complete
    if (_isRequestInProgress && _currentRequestCompleter != null) {
      print('⚠️⚠️⚠️⚠️⚠️ REQUEST BLOCKED - Waiting for current request ⚠️⚠️⚠️⚠️⚠️');
      print('⚠️ Flag _isRequestInProgress: $_isRequestInProgress');
      print('⚠️ Event mobileNumber: ${event.mobileNumber}');
      print('⚠️ Current request counter: $_requestCounter');
      // Wait for current request to complete
      await _currentRequestCompleter!.future;
      print('✅ Previous request completed, but this duplicate event is ignored');
      return;
    }
    
    // Set flag IMMEDIATELY and SYNCHRONOUSLY (before ANY other code)
    // Create completer to track this request
    _isRequestInProgress = true;
    _currentRequestCompleter = Completer<void>();
    _requestCounter++;
    final currentRequestId = _requestCounter;
    
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔒🔒🔒 LOCK ACQUIRED 🔒🔒🔒');
    print('🔢 Request ID: $currentRequestId');
    print('📱 Phone Number: ${event.mobileNumber}');
    print('═══════════════════════════════════════════════════════');
    print('');
    

    // Use print for terminal output (works in all contexts)
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🎯 _onSaveMobileNumberEvent called');
    print('📱 Event mobileNumber: ${event.mobileNumber}');
    print('🔒 Request lock: $_isRequestInProgress');
    print('🔢 Request ID: $currentRequestId');
    print('═══════════════════════════════════════════════════════');

    // Set loading state first
    _mobileNumberModel.isLoading = true;
    emit(UpdateMobileNumberUI(_mobileNumberModel));

    // Emit loading state to show loading dialog
    print('⏳ Emitting OnMobileNumberLoadingState...');
    emit(OnMobileNumberLoadingState());
    
    // Small delay to ensure UI updates before API call
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      // Prepare request body
      final requestBody = jsonEncode({
        'phoneNumber': event.mobileNumber,
      });


      // Make first API call - ensure only one request is made
      print('🌐 About to make HTTP POST request...');
      print('🔢 Request ID: $currentRequestId');

      
      final response = await http.post(
        Uri.parse(_apiUrlCheck),
        headers: HttpHeadersHelper.getDefaultHeaders(),
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      print('📥 HTTP response received');
      print('🔢 Request ID: $currentRequestId');
      print('📊 Status Code: ${response.statusCode}');

      // Log response details
      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 RESPONSE RECEIVED');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');
      

      // Handle response
      if (response.statusCode == 200) {
        // Try to parse response body
        try {
          final responseBody = jsonDecode(response.body);
          print('📋 Parsed Response Body:');
          print(jsonEncode(responseBody));
          
          // Parse response using model
          final mobileNumberResponse = MobileNumberResponse.fromJson(
            responseBody is Map<String, dynamic> 
                ? responseBody 
                : <String, dynamic>{},
          );
          
          print('');
          print('═══════════════════════════════════════════════════════');
          print('📊 RESPONSE MODEL');
          print('═══════════════════════════════════════════════════════');
          print('Success: ${mobileNumberResponse.success}');
          print('Error Code: ${mobileNumberResponse.errorCode ?? "N/A"}');
          print('Error Message: ${mobileNumberResponse.errorMessage ?? "N/A"}');
          print('Error Descriptions: ${mobileNumberResponse.errorDescriptions ?? "N/A"}');
          print('Data - isEmailExists: ${mobileNumberResponse.data?.isEmailExists ?? "N/A"}');
          print('Data - isPhoneNumberExists: ${mobileNumberResponse.data?.isPhoneNumberExists ?? "N/A"}');
          print('═══════════════════════════════════════════════════════');
          print('');
          

          // Extract phoneNumberOtpRequestId, transactionId, isPhoneNumberExists, and isEmailExists from response
          String? phoneNumberOtpRequestId;
          String? transactionId;
          
          // Get isPhoneNumberExists and isEmailExists from the model's data object
          final phoneNumberExists = mobileNumberResponse.data?.isPhoneNumberExists ?? false;
          final emailExists = mobileNumberResponse.data?.isEmailExists ?? false;
          
          // Check root level for phoneNumberOtpRequestId and transactionId (if they exist)
          final responseBodyMap = responseBody is Map<String, dynamic> ? responseBody : null;
          if (responseBodyMap != null) {
            phoneNumberOtpRequestId = responseBodyMap['phoneNumberOtpRequestId']?.toString();
            transactionId = responseBodyMap['transactionId']?.toString();
          }
          
          print('📋 Extracted phoneNumberOtpRequestId: $phoneNumberOtpRequestId');
          print('📋 Extracted transactionId: $transactionId');
          print('📋 Extracted isPhoneNumberExists: $phoneNumberExists');
          print('📋 Extracted isEmailExists: $emailExists');
          
          // Check success and existence flags
          if (mobileNumberResponse.success == true) {
            print('✅✅✅ First API call successful - Success is true ✅✅✅');
            
            // Reset loading state and flag
            _mobileNumberModel.isLoading = false;
            _isRequestInProgress = false;
            _currentRequestCompleter?.complete();
            _currentRequestCompleter = null;
            emit(UpdateMobileNumberUI(_mobileNumberModel));
            
            // Check if phone number OR email exists
            if (phoneNumberExists == true || emailExists == true) {
              // Phone number or email exists - navigate to login screen (DO NOT show verification dialog)
              print('📱 Phone number or email exists (isPhoneNumberExists=$phoneNumberExists, isEmailExists=$emailExists) - Navigating to login screen');
              emit(OnPhoneNumberExistsState());
              return; // Important: return early to prevent showing verification dialog
            } else if (phoneNumberExists == false || emailExists == false) {
              // Phone number or email doesn't exist - call StepVerifyPhone API
              print('📱 Phone number or email doesn\'t exist (isPhoneNumberExists=$phoneNumberExists, isEmailExists=$emailExists) - Calling StepVerifyPhone API');
              
              // Call StepVerifyPhone API
              await _callStepVerifyPhone(event.mobileNumber, emit);
            } else {
              // Unexpected state - default to calling StepVerifyPhone API
              print('⚠️ Unexpected state (isPhoneNumberExists=$phoneNumberExists, isEmailExists=$emailExists) - Defaulting to calling StepVerifyPhone API');
              await _callStepVerifyPhone(event.mobileNumber, emit);
            }
          } else {
            // Success field is false - show error
            print('❌ API call returned success=false');
            final errorMessage = mobileNumberResponse.errorMessage ?? 
                mobileNumberResponse.errorDescriptions ??
                'فشل التحقق من رقم الموبايل';
            emit(OnMobileNumberErrorState(errorMessage));
          }
        } catch (e) {
          // Reset loading state and flag
          _mobileNumberModel.isLoading = false;
          _isRequestInProgress = false;
          _currentRequestCompleter?.complete();
          _currentRequestCompleter = null;
          emit(UpdateMobileNumberUI(_mobileNumberModel));
          
          print('⚠️ Response body parsing failed: $e');
          // If parsing fails, show error
          emit(OnMobileNumberErrorState('فشل في معالجة الاستجابة من الخادم'));
        }
      } else {
        // Error response (non-200 status)
        final errorMessage =
            'Failed to verify phone number: ${response.statusCode}';
        print('❌ Error Response:');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        
        try {
          final errorBody = jsonDecode(response.body);
          print('📋 Parsed Error Body:');
          print(jsonEncode(errorBody));
          
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
            print('🔑 Invalid API Key detected');
            emit(OnMobileNumberErrorState('مفتاح API غير صالح'));
            return;
          }
          
          // Try to parse as MobileNumberResponse to get error message
          final errorResponse = MobileNumberResponse.fromJson(
            errorBody is Map<String, dynamic> 
                ? errorBody 
                : <String, dynamic>{},
          );
          
          final finalErrorMessage = errorResponse.errorMessage ?? 
              errorResponse.errorDescriptions ??
              errorMessage;
          emit(OnMobileNumberErrorState(finalErrorMessage));
        } catch (e) {
          // Reset loading state and flag
          _mobileNumberModel.isLoading = false;
          _isRequestInProgress = false;
          emit(UpdateMobileNumberUI(_mobileNumberModel));
          
          print('⚠️ Error body parsing failed: $e');
          
          // Check if it's an API key error even if parsing fails
          String errorBodyString = response.body.toLowerCase();
          bool isInvalidApiKey = response.statusCode == 401 || 
              response.statusCode == 403 ||
              errorBodyString.contains('invalid api key') ||
              errorBodyString.contains('invalid api') ||
              errorBodyString.contains('api key') ||
              errorBodyString.contains('unauthorized') ||
              errorBodyString.contains('forbidden');
          
          if (isInvalidApiKey) {
            print('🔑 Invalid API Key detected (parsing failed)');
            emit(OnMobileNumberErrorState('مفتاح API غير صالح'));
          } else {
            emit(OnMobileNumberErrorState(errorMessage));
          }
        }
      }
    } catch (e) {
      // Reset loading state and flag
      _mobileNumberModel.isLoading = false;
      _isRequestInProgress = false;
      _currentRequestCompleter?.complete();
      _currentRequestCompleter = null;
      emit(UpdateMobileNumberUI(_mobileNumberModel));
      
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
      }
      
      print('❌ Network or other error: ${e.toString()}');
      print('❌ User-friendly error: $errorMessage');

      emit(OnMobileNumberErrorState(errorMessage));
    } finally {
      // Always reset flag and completer to ensure cleanup
      if (_isRequestInProgress) {
        _isRequestInProgress = false;
        _currentRequestCompleter?.complete();
        _currentRequestCompleter = null;
        print('🔓 Lock released in finally block');
      }
    }
  }

  /// Call StepVerifyPhone API to send OTP
  Future<void> _callStepVerifyPhone(String mobileNumber, emit) async {
    try {
      // Prepare request body
      final requestBody = jsonEncode({
        'phoneNumber': mobileNumber,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 STEP VERIFY PHONE API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlStepVerifyPhone');
      print('Method: POST');
      print('Headers: ${HttpHeadersHelper.getDefaultHeaders()}');
      print('Body: $requestBody');
      print('═══════════════════════════════════════════════════════');
      print('');


      // Make API call
      final response = await http.post(
        Uri.parse(_apiUrlStepVerifyPhone),
        headers: HttpHeadersHelper.getDefaultHeaders(),
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 STEP VERIFY PHONE API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');
      if (response.statusCode == 200) {
        // Parse response using model
        try {
          final responseBody = jsonDecode(response.body);
          final stepVerifyPhoneResponse = StepVerifyPhoneResponse.fromJson(
            responseBody is Map<String, dynamic> 
                ? responseBody 
                : <String, dynamic>{},
          );

          print('');
          print('═══════════════════════════════════════════════════════');
          print('📊 STEP VERIFY PHONE RESPONSE MODEL');
          print('═══════════════════════════════════════════════════════');
          print('Success: ${stepVerifyPhoneResponse.success}');
          print('PhoneNumberOtpRequestId: ${stepVerifyPhoneResponse.phoneNumberOtpRequestId ?? "N/A"}');
          print('TransactionId: ${stepVerifyPhoneResponse.transactionId ?? "N/A"}');
          print('Error Code: ${stepVerifyPhoneResponse.errorCode ?? "N/A"}');
          print('Error Message: ${stepVerifyPhoneResponse.errorMessage ?? "N/A"}');
          print('═══════════════════════════════════════════════════════');
          print('');

          // For the first call (sending OTP), we only need phoneNumberOtpRequestId and transactionId
          // isPhoneNumberConfirmed is only set to true in the second call (verifying OTP)
          final hasRequiredFields = stepVerifyPhoneResponse.phoneNumberOtpRequestId != null &&
              stepVerifyPhoneResponse.phoneNumberOtpRequestId!.isNotEmpty &&
              stepVerifyPhoneResponse.transactionId != null &&
              stepVerifyPhoneResponse.transactionId!.isNotEmpty;
          
          print('📋 Checking response for first StepVerifyPhone call:');
          print('📋 Has phoneNumberOtpRequestId: ${stepVerifyPhoneResponse.phoneNumberOtpRequestId != null && stepVerifyPhoneResponse.phoneNumberOtpRequestId!.isNotEmpty}');
          print('📋 Has transactionId: ${stepVerifyPhoneResponse.transactionId != null && stepVerifyPhoneResponse.transactionId!.isNotEmpty}');
          print('📋 isPhoneNumberConfirmed: ${stepVerifyPhoneResponse.isPhoneNumberConfirmed}');
          print('📋 Has required fields: $hasRequiredFields');
          
          // Check if response is successful - for first call, we only need phoneNumberOtpRequestId and transactionId
          if (hasRequiredFields) {
            // Save to local storage (VerificationCache)
            await VerificationCache().setVerificationData(
              phoneNumberOtpRequestId: stepVerifyPhoneResponse.phoneNumberOtpRequestId!,
              transactionId: stepVerifyPhoneResponse.transactionId!,
              mobileNumber: mobileNumber,
            );

            print('💾 Saved to VerificationCache:');
            print('💾 phoneNumberOtpRequestId: ${stepVerifyPhoneResponse.phoneNumberOtpRequestId}');
            print('💾 transactionId: ${stepVerifyPhoneResponse.transactionId}');
            print('💾 mobileNumber: $mobileNumber');

            // Emit success state to show verification dialog
            print('✅ StepVerifyPhone API successful (OTP sent) - Showing verification dialog');
            emit(OnMobileNumberSavedState(
              phoneNumberOtpRequestId: stepVerifyPhoneResponse.phoneNumberOtpRequestId!,
              transactionId: stepVerifyPhoneResponse.transactionId!,
            ));
          } else {
            // Response doesn't have required fields
            print('❌ StepVerifyPhone API response missing required fields');
            print('❌ phoneNumberOtpRequestId: ${stepVerifyPhoneResponse.phoneNumberOtpRequestId ?? "null"}');
            print('❌ transactionId: ${stepVerifyPhoneResponse.transactionId ?? "null"}');
          final errorMessage = stepVerifyPhoneResponse.errorMessage ??
                stepVerifyPhoneResponse.errorDescriptions ??
                'فشل في الحصول على بيانات التحقق من الخادم';
            emit(OnMobileNumberErrorState(errorMessage));
          }
        } catch (e) {
          print('⚠️ Error parsing StepVerifyPhone response: $e');
          emit(OnMobileNumberErrorState('فشل في معالجة الاستجابة من الخادم'));
        }
      } else {
        // Error response
        String errorMessage = 'فشل في إرسال كود التحقق';
        
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? 
                          errorBody['error'] ?? 
                          errorBody['errorMessage'] ??
                          errorBody['data']?['message'] ??
                          errorBody['data']?['error'] ??
                          'فشل في إرسال كود التحقق';
          }
        } catch (e) {
          print('⚠️ Error parsing error response: $e');
        }

        print('❌ StepVerifyPhone API failed with status code: ${response.statusCode}');
        print('❌ Error message: $errorMessage');

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
          print('🔑 Invalid API Key detected in StepVerifyPhone');
          emit(OnMobileNumberErrorState('مفتاح API غير صالح'));
        } else {
          emit(OnMobileNumberErrorState(errorMessage));
        }
      }
    } catch (e) {
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
        errorMessage = 'حدث خطأ أثناء إرسال كود التحقق: $errorMessage';
      }
      
      print('❌ StepVerifyPhone API error: ${e.toString()}');
      print('❌ User-friendly error: $errorMessage');
     emit(OnMobileNumberErrorState(errorMessage));
    }
  }

}
