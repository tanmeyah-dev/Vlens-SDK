import 'dart:convert';
import 'dart:io';
import 'package:core/bases/base_bloc.dart';
import 'package:core/bases/states/base/init_screen.dart';
import 'package:core/bases/states/general_state/general_render_state.dart';
import 'package:core/utils/network/http_headers_helper.dart';
import 'package:core/utils/cache/verification_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../utils/sdk_http_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../mobile_number/constants/api_urls.dart';
import '../event/username_security_code_event.dart';
import '../model/create_user_response.dart';
import '../model/username_security_code_model.dart';
import '../state/username_security_code_state.dart';
import '../../loginscreen/utils/device_info_helper.dart';

class UsernameSecurityCodeBloc extends BaseBloc {
  final UsernameSecurityCodeModel _model;
  
  /// Get the API URL - uses platform-aware URL helper
  String get _apiUrlCreateUser => ApiUrls.getCreateUserUrl();

  UsernameSecurityCodeBloc(this._model)
      : super(initialState: InitScreen(_model)) {
    on<EnableSaveButtonEvent>(_onEnableSaveButtonEvent);
    on<SaveUsernameSecurityCodeEvent>(_onSaveUsernameSecurityCodeEvent);
  }

  _onEnableSaveButtonEvent(EnableSaveButtonEvent event, emit) {
    _model.isSaveButtonDisabled = !event.isEnabled;
    emit(UpdateUsernameSecurityCodeUI(_model));
  }

  _onSaveUsernameSecurityCodeEvent(SaveUsernameSecurityCodeEvent event, emit) async {
    emit(OnUsernameSecurityCodeLoadingState());

    try {
      // Get device info
      String imei = '';
      String imsi = '';

      try {
        final deviceInfo = DeviceInfoPlugin();
        
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          // Android ID (unique per device/app combination)
          imei = androidInfo.id;
          // IMSI is not directly available via device_info_plus
          // Using Android ID as fallback for IMSI
          imsi = androidInfo.id;
          print('📱 Android device ID: $imei');
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          // identifierForVendor (unique per vendor per device)
          imei = iosInfo.identifierForVendor ?? '';
          // IMSI is not accessible on iOS
          // Using identifierForVendor as fallback for IMSI
          imsi = iosInfo.identifierForVendor ?? '';
          print('📱 iOS identifierForVendor: $imei');
        } else {
          // Fallback for other platforms
          imei = 'device_${DateTime.now().millisecondsSinceEpoch}';
          imsi = 'imsi_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        // If IMEI/IMSI are still empty, use fallback
        if (imei.isEmpty) {
          imei = 'device_${DateTime.now().millisecondsSinceEpoch}';
        }
        if (imsi.isEmpty) {
          imsi = 'imsi_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        print('📱 Final IMEI: $imei');
        print('📱 Final IMSI: $imsi');
      } catch (e) {
        print('⚠️ Error getting device info: $e');
        // Use fallback values if error occurs
        imei = 'fallback_imei_${DateTime.now().millisecondsSinceEpoch}';
        imsi = 'fallback_imsi_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Get geolocation (with safe fallback from helper when unavailable)
      final location = await DeviceInfoHelper.getCurrentLocation();
      final finalLatitude = location['latitude'] ?? 1.0;
      final finalLongitude = location['longitude'] ?? 1.0;

      // Get emailOtpRequestId from cache
      String? emailOtpRequestId = await VerificationCache().getEmailOtpRequestId();
      print('📦 Retrieved emailOtpRequestId from cache: ${emailOtpRequestId != null ? "Found" : "Not found"}');
      
      // Use empty string if not found in cache
      final finalEmailOtpRequestId = emailOtpRequestId ?? '';

      var email = event.email.trim();
      if (email.isEmpty) {
        email = (await VerificationCache().getEmail())?.trim() ?? '';
      }

      // Prepare request body (vlens create-user: no phoneNumberOtpRequestId / transactionId)
      final requestBody = jsonEncode({
        'password': event.securityCode,
        'email': email,
        'emailOtpRequestId': finalEmailOtpRequestId,
        'geoLocation': {
          'latitude': finalLatitude,
          'longitude': finalLongitude,
        },
        'imei': imei,
        'imsi': imsi,
        'phoneNumber': event.mobileNumber,
        'skipEmail': false,
      });

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📤 CREATE USER API REQUEST');
      print('═══════════════════════════════════════════════════════');
      print('URL: $_apiUrlCreateUser');
      print('Method: POST');
      print('Body: $requestBody');
      print('Email OTP Request ID: $finalEmailOtpRequestId');
      print('Email: $email');
      print('═══════════════════════════════════════════════════════');
      print('');

      // Make API call with better error handling
      http.Response response;
      try {
        response = await SdkHttpClient.post(
          Uri.parse(_apiUrlCreateUser),
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
        print('URL Attempted: $_apiUrlCreateUser');
        print('═══════════════════════════════════════════════════════');
        print('');
        rethrow;
      } catch (e) {
        print('❌ Connection error: $e');
        print('❌ URL attempted: $_apiUrlCreateUser');
        rethrow;
      }

      print('');
      print('═══════════════════════════════════════════════════════');
      print('📥 CREATE USER API RESPONSE');
      print('═══════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('═══════════════════════════════════════════════════════');
      print('');

      CreateUserResponse? parsed;
      if (response.body.isNotEmpty) {
        try {
          final map = jsonDecode(response.body);
          if (map is Map<String, dynamic>) {
            parsed = CreateUserResponse.fromJson(map);
          }
        } catch (e) {
          print('⚠️ Error parsing create-user response: $e');
        }
      }

      if (parsed != null &&
          parsed.isBusinessSuccess(httpStatus: response.statusCode)) {
        emit(OnUsernameSecurityCodeSavedState(parsed));
      } else {
        String errorMessage = 'فشل إنشاء المستخدم';
        final parsedMsg = parsed?.message?.trim();
        if (parsedMsg != null && parsedMsg.isNotEmpty) {
          errorMessage = parsedMsg;
        } else if (response.body.isNotEmpty) {
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody is Map<String, dynamic>) {
              errorMessage = errorBody['message']?.toString() ??
                  errorBody['error']?.toString() ??
                  errorBody['errorMessage']?.toString() ??
                  errorMessage;
            }
          } catch (e) {
            print('⚠️ Error parsing error response: $e');
          }
        }
        emit(OnUsernameSecurityCodeErrorState(errorMessage));
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
        userFriendlyMessage = 'حدث خطأ أثناء إنشاء المستخدم. يرجى المحاولة مرة أخرى';
      }
      
      print('❌ Error creating user: $errorMessage');
      print('❌ User-friendly message: $userFriendlyMessage');
      emit(OnUsernameSecurityCodeErrorState(userFriendlyMessage));
    }
  }
}
