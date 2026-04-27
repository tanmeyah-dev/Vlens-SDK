import 'dart:convert';
import 'dart:io';
import 'package:core/bases/base_bloc.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:http/http.dart' as http;
import '../../../utils/sdk_http_client.dart';
import '../../mobile_number/constants/api_urls.dart';
import '../event/loginscreen_event.dart';
import '../model/loginscreen_model.dart';
import '../model/login_response.dart';
import '../state/loginscreen_state.dart';
import '../utils/device_info_helper.dart';

class LoginScreenBloc extends BaseBloc {
  final LoginScreenModel _model;
  
  String get _apiUrlLogin => ApiUrls.getLoginUrl();

  LoginScreenBloc(this._model)
      : super(initialState: InitLoginScreen(data: _model)) {
    on<EnableLoginButtonEvent>(_onEnableLoginButtonEvent);
    on<LoginEvent>(_onLoginEvent);
    on<UpdateLoginScreenUIEvent>(_onUpdateLoginScreenUIEvent);
  }

  _onEnableLoginButtonEvent(EnableLoginButtonEvent event, emit) {
    final newDisabledState = !event.isEnabled;
    // Only emit if the state actually changed to prevent unnecessary updates
    if (_model.isLoginButtonDisabled != newDisabledState) {
      _model.isLoginButtonDisabled = newDisabledState;
      emit(UpdateLoginScreenUI(_model));
    }
  }

  _onUpdateLoginScreenUIEvent(UpdateLoginScreenUIEvent event, emit) {
    emit(UpdateLoginScreenUI(event.model));
  }

  _onLoginEvent(LoginEvent event, emit) async {
    _model.isLoading = true;
    emit(UpdateLoginScreenUI(_model));
    emit(OnLoginLoadingState()); // Emit loading state to show dialog
    
    try {
      // Get device IMEI and location
      print('📱 Getting device information...');
      final deviceId = await DeviceInfoHelper.getDeviceId();
      final location = await DeviceInfoHelper.getCurrentLocation();
      
      print('📱 Device ID (IMEI): $deviceId');
      print('📍 Location: ${location['latitude']}, ${location['longitude']}');
      
      // Prepare request body with all required fields
      final requestBody = jsonEncode({
        'phoneNumber': event.mobileNumber,
        'password': event.password,
        'geoLocation': {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
        },
        'imei': deviceId,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 LOGIN API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlLogin');
      print('Method: POST');
      print('Headers: ${HttpHeadersHelper.getDefaultHeaders()}');
      print('Body: $requestBody');
      print('Mobile Number: ${event.mobileNumber}');
      print('Password: ${'*' * event.password.length}');
      print('IMEI: $deviceId');
      print('GeoLocation: ${location['latitude']}, ${location['longitude']}');
      print('═══════════════════════════════════════════════════════');
      print('');

      // Make API call with better error handling
      http.Response response;
      try {
        response = await SdkHttpClient.post(
          Uri.parse(_apiUrlLogin),
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
        print('URL Attempted: $_apiUrlLogin');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlLogin');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 LOGIN API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      // Only navigate to home if status code is exactly 200
      if (response.statusCode == 200) {
        // Success - parse response
        print('✅ Login API successful - Status Code: 200');
        
        try {
          // Parse response
          if (response.body.isEmpty) {
            print('⚠️ Response body is empty');
            _model.isLoading = false;
            emit(UpdateLoginScreenUI(_model));
            emit(OnLoginErrorState('استجابة فارغة من الخادم'));
            return;
          }
          
          final decoded = jsonDecode(response.body);
          if (decoded is! Map) {
            print('⚠️ Invalid response shape');
            _model.isLoading = false;
            emit(UpdateLoginScreenUI(_model));
            emit(OnLoginErrorState('استجابة غير صالحة من الخادم'));
            return;
          }
          final responseBody = Map<String, dynamic>.from(decoded as Map);
          final rawData = responseBody['data'];
          if (rawData is Map) {
            print('🔍 RAW login data keys: ${rawData.keys.toList()}');
          } else {
            print('🔍 RAW login data is not Map: ${rawData.runtimeType}');
          }

          var loginResponse = LoginResponse.fromJson(responseBody);
          if (loginResponse.data == null && responseBody['data'] is Map) {
            final fallbackData = LoginResponseData.fromJson(
              Map<String, dynamic>.from(responseBody['data'] as Map),
            );
            loginResponse = LoginResponse(
              code: loginResponse.code,
              message: loginResponse.message,
              success: loginResponse.success,
              data: fallbackData,
              errorCode: loginResponse.errorCode,
              errorMessage: loginResponse.errorMessage,
              errorDescriptions: loginResponse.errorDescriptions,
            );
            print('ℹ️ Applied fallback parser from raw response.data map');
          }
          print('✅ Login response parsed successfully');
          if (loginResponse.data != null) {
            final d = loginResponse.data!;
            print('📊 data: success=${loginResponse.success}, code=${loginResponse.code}, '
                'hasPendingRequest=${d.hasPendingRequest}, '
                'isPhoneNumberConfirmationRequired=${d.isPhoneNumberConfirmationRequired}, '
                'phoneNumberOtpRequestId=${d.phoneNumberOtpRequestId}, '
                'transactionId=${d.transactionId}, '
                'accessTokenNull=${d.accessToken == null}, '
                'refreshTokenNull=${d.refreshToken == null}, '
                'encryptedAccessTokenNull=${d.encryptedAccessToken == null}');
          }

          if (!loginResponse.isBusinessSuccess(httpStatus: response.statusCode)) {
            final msg = loginResponse.message?.trim().isNotEmpty == true
                ? loginResponse.message!.trim()
                : (loginResponse.errorMessage?.trim().isNotEmpty == true
                    ? loginResponse.errorMessage!.trim()
                    : 'فشل في تسجيل الدخول');
            _model.isLoading = false;
            emit(UpdateLoginScreenUI(_model));
            emit(OnLoginErrorState(msg));
            return;
          }

          _model.isLoading = false;
          emit(UpdateLoginScreenUI(_model));
          emit(OnLoginSuccessState(loginResponse));
        } catch (e, stackTrace) {
          print('');
          print('═══════════════════════════════════════════════════════');
          print('❌ ERROR PARSING LOGIN RESPONSE');
          print('═══════════════════════════════════════════════════════');
          print('Error: $e');
          print('Error Type: ${e.runtimeType}');
          print('Stack Trace: $stackTrace');
          print('Response Body: ${response.body}');
          print('═══════════════════════════════════════════════════════');
          print('');
          
          _model.isLoading = false;
          emit(UpdateLoginScreenUI(_model));
          emit(OnLoginErrorState('فشل في معالجة الاستجابة من الخادم'));
        }
      } else {
        // Status code is NOT 200 - stay on login screen and show error
        print('❌ Login API failed - Status Code: ${response.statusCode}');
        String errorMessage = 'فشل في تسجيل الدخول';
        
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            // Try multiple common error message fields
            errorMessage = errorBody['message'] ?? 
                          errorBody['Message'] ??
                          errorBody['error'] ?? 
                          errorBody['Error'] ??
                          errorBody['errorMessage'] ??
                          errorBody['ErrorMessage'] ??
                          errorBody['error_message'] ??
                          errorBody['errorMessage'] ??
                          errorBody['data']?['message'] ??
                          errorBody['data']?['Message'] ??
                          errorBody['data']?['error'] ??
                          errorBody['data']?['Error'] ??
                          errorBody['errors']?[0]?['message'] ??
                          errorBody['errors']?[0]?['Message'] ??
                          (errorBody['errors'] is List && (errorBody['errors'] as List).isNotEmpty 
                            ? errorBody['errors'][0].toString() 
                            : null) ??
                          'فشل في تسجيل الدخول';
            
            // If errorMessage is still default, try to get any string value from response
            if (errorMessage == 'فشل في تسجيل الدخول' && errorBody is Map) {
              final values = errorBody.values.where((v) => v is String && v.isNotEmpty).toList();
              if (values.isNotEmpty) {
                errorMessage = values.first.toString();
              }
            }
          } else {
            // No body, use status code based message
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
              case 404:
                errorMessage = 'المسار غير موجود';
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
          print('⚠️ Response body: ${response.body}');
          // Use status code based message if parsing fails
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
            case 404:
              errorMessage = 'المسار غير موجود';
              break;
            case 500:
              errorMessage = 'خطأ في الخادم';
              break;
            default:
              errorMessage = 'فشل في تسجيل الدخول (رمز الخطأ: ${response.statusCode})';
          }
        }

        print('❌ Error message extracted: $errorMessage');
        
        _model.isLoading = false;
        emit(UpdateLoginScreenUI(_model));
        // Emit error state - user stays on login screen
        emit(OnLoginErrorState(errorMessage));
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
        userFriendlyMessage = 'حدث خطأ أثناء تسجيل الدخول. يرجى المحاولة مرة أخرى';
      }
      
      print('❌ Error during login: $errorMessage');
      print('❌ User-friendly message: $userFriendlyMessage');
      _model.isLoading = false;
      emit(UpdateLoginScreenUI(_model));
      emit(OnLoginErrorState(userFriendlyMessage));
    }
  }
}
