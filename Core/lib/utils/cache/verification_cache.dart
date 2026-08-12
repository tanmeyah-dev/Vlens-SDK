import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache for storing verification data (OTP request IDs, transaction IDs, etc.)
class VerificationCache {
  static const String _keyPhoneNumberOtpRequestId = 'phone_number_otp_request_id';
  static const String _keyTransactionId = 'transaction_id';
  static const String _keyMobileNumber = 'mobile_number';
  static const String _keyEmailOtpRequestId = 'email_otp_request_id';
  static const String _keyEmail = 'email';
  static const String _keyOAuthTokenVerificationRequestId =
      'oauth_token_verification_request_id';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyEncryptedAccessToken = 'encrypted_access_token';
  static const String _keyUserName = 'user_name';
  static const String _keyUserFullName = 'user_full_name';
  static const String _keyLatitude = 'cached_latitude';
  static const String _keyLongitude = 'cached_longitude';
  static const String _keyRequestTypeId = 'request_type_id';
  static const String _keyVlensExtractedData = 'vlens_extracted_data';
  static const String _keyVlensTraceResponseBody = 'vlens_trace_response_body';
  static const String _keyLoginResponseData = 'login_response_data';

  /// Save phone number verification data
  Future<void> setVerificationData({
    required String phoneNumberOtpRequestId,
    required String transactionId,
    required String mobileNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhoneNumberOtpRequestId, phoneNumberOtpRequestId);
    await prefs.setString(_keyTransactionId, transactionId);
    await prefs.setString(_keyMobileNumber, mobileNumber);
  }

  /// Persist mobile alone (e.g. when OTP ids are missing but user already entered the number).
  Future<void> setMobileNumber(String mobileNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMobileNumber, mobileNumber.trim());
  }

  /// Save email verification data
  Future<void> setEmailVerificationData({
    required String emailOtpRequestId,
    required String transactionId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmailOtpRequestId, emailOtpRequestId);
    await prefs.setString(_keyTransactionId, transactionId);
    await prefs.setString(_keyEmail, email);
    // Email OTP replaces OAuth verification for this session.
    await prefs.remove(_keyOAuthTokenVerificationRequestId);
  }

  /// Get phone number OTP request ID
  Future<String?> getPhoneNumberOtpRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoneNumberOtpRequestId);
  }

  /// Get email OTP request ID
  Future<String?> getEmailOtpRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmailOtpRequestId);
  }

  /// Get transaction ID
  Future<String?> getTransactionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTransactionId);
  }

  /// Get mobile number
  Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMobileNumber);
  }

  /// Get email
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Persist email alone (e.g. when OTP APIs omit request/transaction IDs).
  Future<void> setEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  /// Save OAuth email verification (replaces email OTP request id).
  Future<void> setOAuthVerificationData({
    required String oAuthTokenVerificationRequestId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyOAuthTokenVerificationRequestId,
      oAuthTokenVerificationRequestId.trim(),
    );
    await prefs.setString(_keyEmail, email.trim());
    // OAuth replaces email OTP — clear any previous OTP id.
    await prefs.remove(_keyEmailOtpRequestId);
  }

  Future<String?> getOAuthTokenVerificationRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOAuthTokenVerificationRequestId);
  }

  Future<void> clearOAuthTokenVerificationRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOAuthTokenVerificationRequestId);
  }

  /// Persist login user/session data for downstream requests.
  Future<void> setLoginSession({
    String? accessToken,
    String? refreshToken,
    String? encryptedAccessToken,
    String? transactionId,
    String? userName,
    String? userFullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      await prefs.setString(_keyAccessToken, accessToken.trim());
    }
    if (refreshToken != null) {
      await prefs.setString(_keyRefreshToken, refreshToken.trim());
    }
    if (encryptedAccessToken != null) {
      await prefs.setString(_keyEncryptedAccessToken, encryptedAccessToken.trim());
    }
    if (transactionId != null) {
      await prefs.setString(_keyTransactionId, transactionId.trim());
    }
    if (userName != null) {
      await prefs.setString(_keyUserName, userName.trim());
    }
    if (userFullName != null) {
      await prefs.setString(_keyUserFullName, userFullName.trim());
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getEncryptedAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEncryptedAccessToken);
  }

  /// Save geo location to reuse the same coordinates across API calls.
  Future<void> setGeoLocation({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLatitude, latitude);
    await prefs.setDouble(_keyLongitude, longitude);
  }

  /// Get cached geo location if available.
  Future<Map<String, double>?> getGeoLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_keyLatitude);
    final longitude = prefs.getDouble(_keyLongitude);
    if (latitude == null || longitude == null) {
      return null;
    }
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Remove stored coordinates (e.g. after invalidating placeholder cache).
  Future<void> clearGeoLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLatitude);
    await prefs.remove(_keyLongitude);
  }

  /// Persist request type id to use in later screens/flows.
  Future<void> setRequestTypeId(int requestTypeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRequestTypeId, requestTypeId);
  }

  /// Get cached request type id if available.
  Future<int?> getRequestTypeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRequestTypeId);
  }

  /// Cache extracted VLens model as JSON for later logins.
  Future<void> setVlensExtractedData(dynamic extractedData) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(extractedData);
    await prefs.setString(_keyVlensExtractedData, encoded);
  }

  /// Read cached VLens extracted model.
  Future<dynamic> getVlensExtractedData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyVlensExtractedData);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  /// Cache full VLens trace response body.
  Future<void> setVlensTraceResponseBody(dynamic responseBody) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(responseBody);
    await prefs.setString(_keyVlensTraceResponseBody, encoded);
  }

  /// Read cached full VLens trace response body.
  Future<dynamic> getVlensTraceResponseBody() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyVlensTraceResponseBody);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  /// Clear cached VLens identity so the next success overwrites cleanly.
  Future<void> clearVlensIdentityData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVlensExtractedData);
    await prefs.remove(_keyVlensTraceResponseBody);
  }

  /// Cache full login response data model (not only session tokens).
  Future<void> setLoginResponseData(dynamic loginResponseData) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(loginResponseData);
    await prefs.setString(_keyLoginResponseData, encoded);
  }

  /// Read cached full login response data model.
  Future<dynamic> getLoginResponseData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLoginResponseData);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  /// Clear all verification data
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhoneNumberOtpRequestId);
    await prefs.remove(_keyTransactionId);
    await prefs.remove(_keyMobileNumber);
    await prefs.remove(_keyEmailOtpRequestId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyOAuthTokenVerificationRequestId);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyEncryptedAccessToken);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserFullName);
    await prefs.remove(_keyLatitude);
    await prefs.remove(_keyLongitude);
    await prefs.remove(_keyRequestTypeId);
    await prefs.remove(_keyVlensExtractedData);
    await prefs.remove(_keyVlensTraceResponseBody);
    await prefs.remove(_keyLoginResponseData);
  }
}
