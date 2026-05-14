import 'dart:convert';
import 'dart:io';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/bases/states/general_state/general_render_state.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_error_parser.dart';
import '../../../utils/sdk_http_client.dart';
import '../../validate_user/constants/api_urls.dart';
import '../event/email_screen_event.dart';
import '../model/email_screen_model.dart';
import '../model/send_email_otp_response.dart';
import '../state/email_screen_state.dart';

class EmailScreenBloc extends BaseBloc {
  final EmailScreenModel _model;
  
  String get _apiUrlStepVerifyEmail => ApiUrls.getSendEmailOtpUrl();

  EmailScreenBloc(this._model)
      : super(initialState: InitScreen(_model)) {
    on<EnableSaveButtonEvent>(_onEnableSaveButtonEvent);
    on<SaveEmailEvent>(_onSaveEmailEvent);
  }

  _onEnableSaveButtonEvent(EnableSaveButtonEvent event, emit) {
    _model.isSaveButtonDisabled = !event.isEnabled;
    emit(UpdateEmailScreenUI(_model));
  }

  _onSaveEmailEvent(SaveEmailEvent event, emit) async {
    _model.isLoading = true;
    emit(UpdateEmailScreenUI(_model));
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
        response = await SdkHttpClient.post(
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
            emit(UpdateEmailScreenUI(_model));
            emit(OnEmailErrorState('استجابة فارغة من الخادم'));
            return;
          }
          
          final responseBody = jsonDecode(response.body);
          print('✅ JSON decoded successfully');
          print('📋 Response body: $responseBody');
          
          final sendEmailOtpResponse = SendEmailOtpResponse.fromJson(
            responseBody is Map<String, dynamic> 
                ? responseBody 
                : <String, dynamic>{},
          );
          
          print('✅ SendEmailOtpResponse model created successfully');
          
          print('');
          print('═══════════════════════════════════════════════════════');
          print('📊 SEND EMAIL OTP RESPONSE MODEL');
          print('═══════════════════════════════════════════════════════');
          print('Code: ${sendEmailOtpResponse.code ?? "N/A"}');
          print('Message: ${sendEmailOtpResponse.message ?? "N/A"}');
          print('Success: ${sendEmailOtpResponse.success}');
          print('emailConfirmed: ${sendEmailOtpResponse.data?.emailConfirmed}');
          print('EmailOtpRequestId: ${sendEmailOtpResponse.data?.emailOtpRequestId ?? "N/A"}');
          print('TransactionId: ${sendEmailOtpResponse.data?.transactionId ?? "N/A"}');
          print('═══════════════════════════════════════════════════════');
          print('');
          
          if (!sendEmailOtpResponse.success) {
            _model.isLoading = false;
            emit(UpdateEmailScreenUI(_model));
            emit(OnEmailErrorState(
                sendEmailOtpResponse.message ?? 'فشل في التحقق من الإيميل'));
            return;
          }

          // Always persist trimmed email for username / create-user screens.
          final trimmedEmail = event.email.trim();
          await VerificationCache().setEmail(trimmedEmail);

          final isEmailConfirmed =
              sendEmailOtpResponse.data?.emailConfirmed ?? false;
          final emailOtpRequestId = sendEmailOtpResponse.data?.emailOtpRequestId;
          final transactionId = sendEmailOtpResponse.data?.transactionId;

          // Save IDs when present (some API versions may omit them).
          if (emailOtpRequestId != null &&
              emailOtpRequestId.isNotEmpty &&
              transactionId != null &&
              transactionId.isNotEmpty) {
            await VerificationCache().setEmailVerificationData(
              emailOtpRequestId: emailOtpRequestId,
              transactionId: transactionId,
              email: trimmedEmail,
            );
            
            print('💾 Saved email verification data to cache:');
            print('💾 emailOtpRequestId: $emailOtpRequestId');
            print('💾 transactionId: $transactionId');
            print('💾 email: $trimmedEmail');
          } else {
            print('ℹ️ send-otp response did not include emailOtpRequestId/transactionId');
          }
            
          // Emit state based on confirmation status.
          _model.isLoading = false;
          emit(UpdateEmailScreenUI(_model));

          if (isEmailConfirmed) {
            print('✅ Email already confirmed - navigating to username security screen');
            emit(OnEmailConfirmedState());
          } else {
            print('✅ Email not confirmed - showing verification dialog');
            emit(OnEmailVerificationRequiredState(
              email: trimmedEmail,
              emailOtpRequestId: emailOtpRequestId,
              transactionId: transactionId,
            ));
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
          emit(UpdateEmailScreenUI(_model));
          emit(OnEmailErrorState('فشل في معالجة الاستجابة من الخادم'));
        }
      } else {
        // Error response
        String errorMessage = 'فشل في التحقق من الإيميل';
        final apiErrorMessage = ApiErrorParser.extractMessage(
          response.body,
          fallbackMessage: errorMessage,
        );
        if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
          errorMessage = apiErrorMessage;
        }
        
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
            if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
              errorMessage = apiErrorMessage;
            }
          }
        } catch (e) {
          print('⚠️ Error parsing error response: $e');
          if (response.statusCode == 417 && apiErrorMessage.trim().isNotEmpty) {
            errorMessage = apiErrorMessage;
          }
        }

        print('❌ StepVerifyEmail API failed with status code: ${response.statusCode}');
        print('❌ Error message: $errorMessage');
        
        _model.isLoading = false;
        emit(UpdateEmailScreenUI(_model));
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
      emit(UpdateEmailScreenUI(_model));
      emit(OnEmailErrorState(userFriendlyMessage));
    }
  }

}
