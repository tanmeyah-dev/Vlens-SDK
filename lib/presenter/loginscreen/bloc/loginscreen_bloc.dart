import 'dart:convert';
import 'dart:io';
import 'package:core/bases/base_bloc.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:http/http.dart' as http;
import '../event/loginscreen_event.dart';
import '../model/loginscreen_model.dart';
import '../state/loginscreen_state.dart';
import '../utils/device_info_helper.dart';

class LoginScreenBloc extends BaseBloc {
  final LoginScreenModel _model;
  
  static const String _apiUrlLogin =
      'https://api.vlenseg.com/api/DigitalIdentity/Login';

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
        response = await http.post(
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

      if (response.statusCode == 200) {
        // Success - parse response
        print('✅ Login API successful');
        
        try {
          // Parse response
          if (response.body.isEmpty) {
            print('⚠️ Response body is empty');
            _model.isLoading = false;
            emit(UpdateLoginScreenUI(_model));
            emit(OnLoginErrorState('استجابة فارغة من الخادم'));
            return;
          }
          
          final responseBody = jsonDecode(response.body);
          print('✅ JSON decoded successfully');
          print('📋 Response body: $responseBody');
          
          // Print formatted response
          print('');
          print('═══════════════════════════════════════════════════════');
          print('📊 LOGIN RESPONSE DATA');
          print('═══════════════════════════════════════════════════════');
          if (responseBody is Map<String, dynamic>) {
            responseBody.forEach((key, value) {
              print('$key: $value');
            });
          } else {
            print('Response: $responseBody');
          }
          print('═══════════════════════════════════════════════════════');
          print('');
          
          _model.isLoading = false;
          emit(UpdateLoginScreenUI(_model));
          emit(OnLoginSuccessState());
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
        // Error response
        String errorMessage = 'فشل في تسجيل الدخول';
        
        try {
          if (response.body.isNotEmpty) {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ?? 
                          errorBody['error'] ?? 
                          errorBody['errorMessage'] ??
                          errorBody['error_message'] ??
                          errorBody['data']?['message'] ??
                          errorBody['data']?['error'] ??
                          'فشل في تسجيل الدخول';
          }
        } catch (e) {
          print('⚠️ Error parsing error response: $e');
        }

        print('❌ Login API failed with status code: ${response.statusCode}');
        print('❌ Error message: $errorMessage');
        
        _model.isLoading = false;
        emit(UpdateLoginScreenUI(_model));
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
