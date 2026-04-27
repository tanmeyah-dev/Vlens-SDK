import 'package:shared_preferences/shared_preferences.dart';

/// Cache for storing verification data (OTP request IDs, transaction IDs, etc.)
class VerificationCache {
  static const String _keyPhoneNumberOtpRequestId = 'phone_number_otp_request_id';
  static const String _keyTransactionId = 'transaction_id';
  static const String _keyMobileNumber = 'mobile_number';
  static const String _keyEmailOtpRequestId = 'email_otp_request_id';
  static const String _keyEmail = 'email';
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyEncryptedAccessToken = 'encrypted_access_token';
  static const String _keyUserName = 'user_name';
  static const String _keyUserFullName = 'user_full_name';

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

  /// Clear all verification data
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhoneNumberOtpRequestId);
    await prefs.remove(_keyTransactionId);
    await prefs.remove(_keyMobileNumber);
    await prefs.remove(_keyEmailOtpRequestId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyEncryptedAccessToken);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserFullName);
  }
}
