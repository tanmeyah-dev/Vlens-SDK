import 'dart:io';
import 'package:flutter/foundation.dart';

/// Helper class to get the correct API base URL based on the platform
/// For Android Emulator: uses 10.0.2.2 (maps to host's localhost)
/// For iOS Simulator: uses localhost
/// For Physical Devices: uses the actual IP address
class ApiUrls {
  // Base IP address for local development server
  static const String _localServerIp = '192.168.51.187';
  static const String _localServerPort = '8088';
  
  // Set to true if you're using a physical device (not emulator/simulator)
  // Set to false if you're using Android emulator or iOS simulator
  static bool usePhysicalDeviceIp = true;
  
  // Set to false if your server uses HTTP instead of HTTPS
  // Set to true if your server uses HTTPS (default)
  static bool useHttps = true;
  
  /// Get the protocol (http or https)
  static String get _protocol => useHttps ? 'https' : 'http';
  
  /// Get the base URL for local development server
  /// Automatically adjusts based on platform
  static String getLocalBaseUrl() {
    final protocol = _protocol;
    
    if (kIsWeb) {
      // Web platform - use localhost
      return '$protocol://localhost:$_localServerPort';
    }
    
    if (Platform.isAndroid) {
      if (usePhysicalDeviceIp) {
        // Physical Android device - use actual IP (must be on same network)
        return '$protocol://$_localServerIp:$_localServerPort';
      } else {
        // Android Emulator uses 10.0.2.2 to access host's localhost
        return '$protocol://10.0.2.2:$_localServerPort';
      }
    } else if (Platform.isIOS) {
      if (usePhysicalDeviceIp) {
        // Physical iOS device - use actual IP (must be on same network)
        return '$protocol://$_localServerIp:$_localServerPort';
      } else {
        // iOS Simulator uses localhost
        return '$protocol://localhost:$_localServerPort';
      }
    }
    
    // Default fallback
    return '$protocol://$_localServerIp:$_localServerPort';
  }
  
  /// Get the full URL for verify phone API
  static String getVerifyPhoneUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/verify/phone';
  }
  
  /// Create user (vlens); same host as other fixed local endpoints in the SDK.
  static String getCreateUserUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/create-user';
  }

  /// Login (vlens).
  static String getLoginUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/login';
  }

  /// Login verify OTP (vlens).
  static String getLoginVerifyOtpUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/login/verify-otp';
  }

  static String getIdentityCheckUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/check';
  }

  static String getSendPhoneOtpUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/phone/send-otp';
  }

  static String getVerifyPhoneOtpUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/phone/verify-otp';
  }

  static String getSendEmailOtpUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/email/send-otp';
  }

  static String getVerifyEmailOtpUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/digital/identity/email/verify-otp';
  }

  /// Request types list.
  static String getRequestTypesUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/request/types';
  }

  /// Request eligibility.
  static String getRequestEligibilityUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/request/eligibility';
  }

  /// Request fields by request type id.
  static String getRequestFieldsUrl({int? requestTypeId}) {
    final base = '${getLocalBaseUrl()}/vlens/api/v1/request/fields';
    if (requestTypeId == null) return base;
    return '$base?requestTypeId=$requestTypeId';
  }

  /// Create request.
  static String getRequestCreateUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/request/create';
  }

  /// Get current request.
  static String getRequestCurrentUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/request/current';
  }

  /// Customer lookups (gender, religion, qualification, …).
  static String getCustomersLookupsUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/mobile/customers/lookups';
  }

  /// E-contract customer step OTP.
  static String getEContractCustomerStepOtpUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/e-contract/customer/step/otp';
  }

  /// E-contract customer validate OTP.
  static String getEContractCustomerValidateOtpUrl() {
    return '${getLocalBaseUrl()}/vlens/api/v1/e-contract/customer/validate/otp';
  }

  /// Check if running on emulator/simulator
  static bool isRunningOnEmulator() {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      // Android emulator typically uses 10.0.2.2
      // You can add more sophisticated detection if needed
      return true; // Assume emulator for now
    } else if (Platform.isIOS) {
      // iOS simulator
      return true;
    }
    return false;
  }
  
  /// Get URL for physical device (use actual IP)
  static String getPhysicalDeviceUrl() {
    return '$_protocol://$_localServerIp:$_localServerPort';
  }
}
