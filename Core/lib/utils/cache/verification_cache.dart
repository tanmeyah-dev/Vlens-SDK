import 'package:shared_preferences/shared_preferences.dart';

/// Cache for storing verification data (OTP request IDs, transaction IDs, etc.)
class VerificationCache {
  static const String _keyPhoneNumberOtpRequestId = 'phone_number_otp_request_id';
  static const String _keyTransactionId = 'transaction_id';
  static const String _keyMobileNumber = 'mobile_number';
  static const String _keyEmailOtpRequestId = 'email_otp_request_id';
  static const String _keyEmail = 'email';

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

  /// Clear all verification data
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhoneNumberOtpRequestId);
    await prefs.remove(_keyTransactionId);
    await prefs.remove(_keyMobileNumber);
    await prefs.remove(_keyEmailOtpRequestId);
    await prefs.remove(_keyEmail);
  }
}
