import 'dart:convert';
import 'dart:io';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/bases/states/general_state/general_render_state.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:http/http.dart' as http;
import '../event/email_input_event.dart';
import '../model/email_input_model.dart';
import '../model/step_verify_email_response.dart';
import '../state/email_input_state.dart';

class EmailInputBloc extends BaseBloc {
  final EmailInputModel _model;
  
  static const String _apiUrlStepVerifyEmail =
      'https://api.vlenseg.com/api/DigitalIdentity/Register/StepVerifyEmail';

  EmailInputBloc(this._model)
      : super(initialState: InitScreen(_model)) {
    on<EnableSaveButtonEvent>(_onEnableSaveButtonEvent);
    on<SaveEmailEvent>(_onSaveEmailEvent);
  }

  _onEnableSaveButtonEvent(EnableSaveButtonEvent event, emit) {
    _model.isSaveButtonDisabled = !event.isEnabled;
    emit(UpdateEmailInputUI(_model));
  }

  _onSaveEmailEvent(SaveEmailEvent event, emit) async {
    _model.isLoading = true;
    emit(UpdateEmailInputUI(_model));
    emit(OnEmailLoadingState()); // Emit loading state to show dialog
    
    try {
      // Prepare request body
      final requestBody = jsonEncode({
        'email': event.email,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 STEP VERIFY EMAIL API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlStepVerifyEmail');
      print('Method: POST');
      print('Headers: ${HttpHeadersHelper.getDefaultHeaders()}');
      print('Body: $requestBody');
      print('Email: ${event.email}');
      print('═══════════════════════════════════════════════════════');
      print('');


      // Make API call with better error handling
      http.Response response;
      try {
        response = await http.post(
          Uri.parse(_apiUrlStepVerifyEmail),
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
        print('URL Attempted: $_apiUrlStepVerifyEmail');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlStepVerifyEmail');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 STEP VERIFY EMAIL API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');


      if (response.statusCode == 200) {
        // Success - parse response and show verification dialog
        print('✅ StepVerifyEmail API successful');
        
        try {
          // Parse response
          if (response.body.isEmpty) {
            print('⚠️ Response body is empty');
            _model.isLoading = false;
            emit(UpdateEmailInputUI(_model));
            emit(OnEmailErrorState('استجابة فارغة من الخادم'));
            return;
          }
          
          final responseBody = jsonDecode(response.body);
          print('✅ JSON decoded successfully');
          print('📋 Response body: $responseBody');
          
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
          print('═══════════════════════════════════════════════════════');
          print('');
          
          // Check if we have the required IDs to show verification dialog
          if (stepVerifyEmailResponse.emailOtpRequestId != null && 
              stepVerifyEmailResponse.emailOtpRequestId!.isNotEmpty &&
              stepVerifyEmailResponse.transactionId != null && 
              stepVerifyEmailResponse.transactionId!.isNotEmpty) {
            // Save emailOtpRequestId and transactionId to cache
            await VerificationCache().setEmailVerificationData(
              emailOtpRequestId: stepVerifyEmailResponse.emailOtpRequestId!,
              transactionId: stepVerifyEmailResponse.transactionId!,
              email: event.email,
            );
            
            print('💾 Saved email verification data to cache:');
            print('💾 emailOtpRequestId: ${stepVerifyEmailResponse.emailOtpRequestId}');
            print('💾 transactionId: ${stepVerifyEmailResponse.transactionId}');
            print('💾 email: ${event.email}');
            
            // Emit state to show verification dialog
            _model.isLoading = false;
            emit(UpdateEmailInputUI(_model));
            emit(OnEmailVerificationRequiredState(
              email: event.email,
              emailOtpRequestId: stepVerifyEmailResponse.emailOtpRequestId!,
              transactionId: stepVerifyEmailResponse.transactionId!,
            ));
          } else {
            // Missing required IDs
            print('❌ StepVerifyEmail API response missing required fields');
            _model.isLoading = false;
            emit(UpdateEmailInputUI(_model));
            emit(OnEmailErrorState('فشل في الحصول على بيانات التحقق من الإيميل'));
          }
        } catch (e, stackTrace) {
          print('');
          print('═══════════════════════════════════════════════════════');
          print('❌ ERROR PARSING STEP VERIFY EMAIL RESPONSE');
          print('═══════════════════════════════════════════════════════');
          print('Error: $e');
          print('Error Type: ${e.runtimeType}');
          print('Stack Trace: $stackTrace');
          print('Response Body: ${response.body}');
          print('═══════════════════════════════════════════════════════');
          print('');
          
          
          _model.isLoading = false;
          emit(UpdateEmailInputUI(_model));
          emit(OnEmailErrorState('فشل في معالجة الاستجابة من الخادم'));
        }
      } else {
        // Error response
        String errorMessage = 'فشل في التحقق من الإيميل';
        
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? 
                          errorBody['error'] ?? 
                          errorBody['errorMessage'] ??
                          errorBody['error_message'] ??
                          errorBody['data']?['message'] ??
                          errorBody['data']?['error'] ??
                          'فشل في التحقق من الإيميل';
          }
        } catch (e) {
          print('⚠️ Error parsing error response: $e');
        }

        print('❌ StepVerifyEmail API failed with status code: ${response.statusCode}');
        print('❌ Error message: $errorMessage');
        
        _model.isLoading = false;
        emit(UpdateEmailInputUI(_model));
        emit(OnEmailErrorState(errorMessage));
      }
    } catch (e) {
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
        userFriendlyMessage = 'حدث خطأ أثناء التحقق من الإيميل. يرجى المحاولة مرة أخرى';
      }
      
      print('❌ Error verifying email: $errorMessage');
      print('❌ User-friendly message: $userFriendlyMessage');
      _model.isLoading = false;
      emit(UpdateEmailInputUI(_model));
      emit(OnEmailErrorState(userFriendlyMessage));
    }
  }
}
