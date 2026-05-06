import 'dart:async';
import 'dart:convert';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_http_client.dart';
import '../constants/api_urls.dart';
import '../event/mobile_number_event.dart';
import '../model/mobile_number_model.dart';
import '../model/mobile_number_response.dart';
import '../model/send_phone_otp_response.dart';
import '../state/mobile_number_state.dart';

class MobileNumberBloc extends BaseBloc {
  final MobileNumberModel _mobileNumberModel;
  String get _apiUrlCheck => ApiUrls.getIdentityCheckUrl();
  String get _apiUrlStepVerifyPhone => ApiUrls.getSendPhoneOtpUrl();
  
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

      
      final response = await SdkHttpClient.post(
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
          print('Code: ${mobileNumberResponse.code ?? "N/A"}');
          print('Message: ${mobileNumberResponse.message ?? "N/A"}');
          print(
              'Data - emailExists: ${mobileNumberResponse.data?.emailExists ?? "N/A"}');
          print(
              'Data - phoneNumberExists: ${mobileNumberResponse.data?.phoneNumberExists ?? "N/A"}');
          print('═══════════════════════════════════════════════════════');
          print('');
          

          final phoneNumberExists =
              mobileNumberResponse.data?.phoneNumberExists ?? false;
          print('📋 Extracted phoneNumberExists: $phoneNumberExists');
          
          // Check success and phone existence flag
          if (mobileNumberResponse.success == true) {
            print('✅✅✅ First API call successful - Success is true ✅✅✅');
            
            // Reset loading state and flag
            _mobileNumberModel.isLoading = false;
            _isRequestInProgress = false;
            _currentRequestCompleter?.complete();
            _currentRequestCompleter = null;
            emit(UpdateMobileNumberUI(_mobileNumberModel));
            
            // phone exists -> login screen
            if (phoneNumberExists == true) {
              print('📱 phoneNumberExists=true - Navigating to login screen');
              emit(OnPhoneNumberExistsState());
              return; // Important: return early to prevent showing verification dialog
            } else {
              // phone doesn't exist -> send OTP
              print(
                  '📱 phoneNumberExists=false - Calling send OTP API and then opening verification dialog');
              
              // Call StepVerifyPhone API
              await _callStepVerifyPhone(event.mobileNumber, emit);
            }
          } else {
            // Success field is false - show error
            print('❌ API call returned success=false');
            final errorMessage = mobileNumberResponse.message ??
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
        final apiErrorMessage = ApiErrorParser.extractMessage(
          response.body,
          fallbackMessage: errorMessage,
        );
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
          
          final finalErrorMessage = (response.statusCode == 417 &&
                  apiErrorMessage.trim().isNotEmpty)
              ? apiErrorMessage
              : (errorResponse.message ?? errorMessage);
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
            if (response.statusCode == 417 &&
                apiErrorMessage.trim().isNotEmpty) {
              emit(OnMobileNumberErrorState(apiErrorMessage));
            } else {
              emit(OnMobileNumberErrorState(errorMessage));
            }
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
      final response = await SdkHttpClient.post(
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
        // Parse send-otp response using dedicated model
        try {
          final responseBody = jsonDecode(response.body);
          final sendOtpResponse = SendPhoneOtpResponse.fromJson(
            responseBody is Map<String, dynamic> 
                ? responseBody 
                : <String, dynamic>{},
          );

          print('');
          print('═══════════════════════════════════════════════════════');
          print('📊 SEND OTP RESPONSE MODEL');
          print('═══════════════════════════════════════════════════════');
          print('Code: ${sendOtpResponse.code ?? "N/A"}');
          print('Message: ${sendOtpResponse.message ?? "N/A"}');
          print('Success: ${sendOtpResponse.success}');
          print('phoneOtpExpireInSeconds: ${sendOtpResponse.data?.phoneOtpExpireInSeconds ?? "N/A"}');
          print('isPhoneNumberConfirmed: ${sendOtpResponse.data?.isPhoneNumberConfirmed}');
          print('═══════════════════════════════════════════════════════');
          print('');

          final isApiSuccessful = sendOtpResponse.success;
          final isPhoneNumberConfirmed =
              sendOtpResponse.data?.isPhoneNumberConfirmed ?? false;
          
          print('📋 Checking response for send-otp call:');
          print('📋 API success: $isApiSuccessful');
          print('📋 isPhoneNumberConfirmed: $isPhoneNumberConfirmed');
          
          if (isApiSuccessful) {
            if (isPhoneNumberConfirmed) {
              print('✅ Phone already confirmed - navigating to login screen');
              emit(OnPhoneNumberExistsState());
            } else {
              print('✅ Phone not confirmed - showing verification dialog');
              emit(OnMobileNumberSavedState());
            }
          } else {
            print('❌ StepVerifyPhone API unsuccessful response');
            final errorMessage = sendOtpResponse.message ??
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
            final extractedMessage = _extractApiErrorMessage(errorBody);
            if (extractedMessage != null && extractedMessage.isNotEmpty) {
              errorMessage = extractedMessage;
            }
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

  String? _extractApiErrorMessage(dynamic body) {
    if (body is! Map) return null;

    final map = Map<String, dynamic>.from(body as Map);

    String? readString(Map<String, dynamic> source, List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return null;
    }

    final topLevel = readString(map, const [
      'error_message',
      'errorMessage',
      'message',
      'Message',
      'error',
      'Error',
      'errorDescription',
      'errorDescriptions',
    ]);
    if (topLevel != null) return topLevel;

    final data = map['data'];
    if (data is Map) {
      final nested = readString(Map<String, dynamic>.from(data as Map), const [
        'error_message',
        'errorMessage',
        'message',
        'Message',
        'error',
        'Error',
        'errorDescription',
        'errorDescriptions',
      ]);
      if (nested != null) return nested;
    }

    final errors = map['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
      if (first is Map) {
        final nested = readString(Map<String, dynamic>.from(first as Map), const [
          'message',
          'Message',
          'error',
          'Error',
          'error_message',
          'errorMessage',
          'description',
        ]);
        if (nested != null) return nested;
      }
    }

    return null;
  }

}
