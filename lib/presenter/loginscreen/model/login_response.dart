/// vlens login: `POST .../digital/identity/login`
///
/// Example envelope:
/// `{ "code": 0, "message": "...", "success": true, "data": { ... } }`
/// Some responses omit root `code` / `message` / `success` and only return `data`.
class LoginResponse {
  final int? code;
  final String? message;
  final bool success;
  final LoginResponseData? data;

  /// Legacy / alternate error shape at root.
  final String? errorCode;
  final String? errorMessage;
  final List<String>? errorDescriptions;

  const LoginResponse({
    this.code,
    this.message,
    required this.success,
    this.data,
    this.errorCode,
    this.errorMessage,
    this.errorDescriptions,
  });

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static bool _parseBool(dynamic v, {required bool ifNull}) {
    if (v == null) return ifNull;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return ifNull;
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    LoginResponseData? data;
    if (json['data'] is Map) {
      final raw = Map<String, dynamic>.from(json['data'] as Map);
      // Some gateways put tokens on the root; merge into `data` for one shape.
      if (raw['accessToken'] == null && json['accessToken'] != null) {
        raw['accessToken'] = json['accessToken'];
      }
      if (raw['refreshToken'] == null && json['refreshToken'] != null) {
        raw['refreshToken'] = json['refreshToken'];
      }
      data = LoginResponseData.fromJson(raw);
    }

    final tokenOk = (data?.accessToken ?? '').trim().isNotEmpty ||
        (data?.encryptedAccessToken ?? '').trim().isNotEmpty;
    final success = _parseBool(json['success'], ifNull: tokenOk);

    List<String>? descriptions;
    final raw = json['error_descriptions'];
    if (raw is List) {
      descriptions = raw.map((e) => e.toString()).toList();
    }

    return LoginResponse(
      code: _parseInt(json['code']),
      message: json['message']?.toString(),
      success: success,
      data: data,
      errorCode: json['error_code']?.toString(),
      errorMessage: json['error_message']?.toString(),
      errorDescriptions: descriptions,
    );
  }

  /// Used after OTP re-login in [VerifyUserOTPDialog].
  bool get isSuccess {
    if (data == null) return false;
    if (errorCode != null && errorCode!.trim().isNotEmpty) return false;
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) return false;
    final d = data!;
    return success ||
        (d.accessToken ?? '').trim().isNotEmpty ||
        (d.encryptedAccessToken ?? '').trim().isNotEmpty;
  }

  /// HTTP 200 + parseable business success for navigation.
  ///
  /// Do **not** treat `code != 0` alone as failure: some APIs use `code: 200`
  /// or other non-zero OK values. Rely on [success], bearer token, or
  /// [encryptedAccessToken] inside [data].
  bool isBusinessSuccess({required int httpStatus}) {
    if (httpStatus != 200) return false;
    final d = data;
    if (d == null) return false;
    if (errorCode != null && errorCode!.trim().isNotEmpty) return false;
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) return false;

    final hasBearer = (d.accessToken ?? '').trim().isNotEmpty;
    final hasEncrypted = (d.encryptedAccessToken ?? '').trim().isNotEmpty;
    if (success || hasBearer || hasEncrypted) return true;

    // No positive signal: treat numeric `code` only then (0 = OK, null = unknown).
    if (code != null && code != 0) return false;
    return false;
  }
}

/// `data` object from login / login-with-OTP.
class LoginResponseData {
  final bool hasPendingRequest;
  final String? maskedPhoneNumber;
  final bool isEmailConfirmationRequired;
  final bool isEmailConfirmed;
  final bool isPhoneNumberConfirmationRequired;
  final bool isPhoneNumberConfirmed;
  final String? phoneNumberOtp;
  final String? phoneNumberOtpRequestId;
  final String? emailOtpRequestId;
  final bool isDigitalIdentityVerified;
  final String? accessToken;
  final String? refreshToken;
  final String? encryptedAccessToken;
  final int? phoneOtpExpireInSeconds;
  final int? emailOtpExpireInSeconds;
  final String? userName;
  final String? userFullName;
  final dynamic user;
  final String? redirectUri;
  final String? transactionId;

  const LoginResponseData({
    this.hasPendingRequest = false,
    this.maskedPhoneNumber,
    this.isEmailConfirmationRequired = false,
    this.isEmailConfirmed = false,
    this.isPhoneNumberConfirmationRequired = false,
    this.isPhoneNumberConfirmed = false,
    this.phoneNumberOtp,
    this.phoneNumberOtpRequestId,
    this.emailOtpRequestId,
    this.isDigitalIdentityVerified = false,
    this.accessToken,
    this.refreshToken,
    this.encryptedAccessToken,
    this.phoneOtpExpireInSeconds,
    this.emailOtpExpireInSeconds,
    this.userName,
    this.userFullName,
    this.user,
    this.redirectUri,
    this.transactionId,
  });

  static bool _bool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return fallback;
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      hasPendingRequest: _bool(json['hasPendingRequest']),
      maskedPhoneNumber: json['maskedPhoneNumber']?.toString(),
      isEmailConfirmationRequired:
          _bool(json['isEmailConfirmationRequired']),
      isEmailConfirmed: _bool(json['isEmailConfirmed']),
      isPhoneNumberConfirmationRequired:
          _bool(json['isPhoneNumberConfirmationRequired']),
      isPhoneNumberConfirmed: _bool(json['isPhoneNumberConfirmed']),
      phoneNumberOtp:
          (json['phoneNumberOtp'] ?? json['phoneOtp'])?.toString(),
      phoneNumberOtpRequestId: json['phoneNumberOtpRequestId']?.toString(),
      emailOtpRequestId: json['emailOtpRequestId']?.toString(),
      isDigitalIdentityVerified: _bool(json['isDigitalIdentityVerified']),
      accessToken: json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      encryptedAccessToken: json['encryptedAccessToken']?.toString(),
      phoneOtpExpireInSeconds: _int(json['phoneOtpExpireInSeconds']),
      emailOtpExpireInSeconds: _int(json['emailOtpExpireInSeconds']),
      userName: json['userName']?.toString(),
      userFullName: json['userFullName']?.toString(),
      user: json['user'],
      redirectUri: json['redirectUri']?.toString(),
      transactionId: json['transactionId']?.toString(),
    );
  }
}
