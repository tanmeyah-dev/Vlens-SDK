/// API response for DigitalIdentity/Login.
class LoginResponse {
  final LoginResponseData? data;
  final String? errorCode;
  final String? errorMessage;
  final List<String>? errorDescriptions;

  const LoginResponse({
    this.data,
    this.errorCode,
    this.errorMessage,
    this.errorDescriptions,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      data: json['data'] != null
          ? LoginResponseData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
      errorCode: json['error_code']?.toString(),
      errorMessage: json['error_message']?.toString(),
      errorDescriptions: json['error_descriptions'] != null
          ? (json['error_descriptions'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
    );
  }

  bool get isSuccess => errorCode == null && errorMessage == null;
}

/// Inner "data" object of the login response.
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
  final String accessToken;
  final String refreshToken;
  final String? encryptedAccessToken;
  final int phoneOtpExpireInSeconds;
  final int emailOtpExpireInSeconds;
  final String? userName;
  final String? userFullName;
  final dynamic user;
  final String? redirectUri;
  final String transactionId;

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
    required this.accessToken,
    required this.refreshToken,
    this.encryptedAccessToken,
    this.phoneOtpExpireInSeconds = 0,
    this.emailOtpExpireInSeconds = 0,
    this.userName,
    this.userFullName,
    this.user,
    this.redirectUri,
    required this.transactionId,
  });

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
      hasPendingRequest: json['hasPendingRequest'] as bool? ?? false,
      maskedPhoneNumber: json['maskedPhoneNumber'] as String?,
      isEmailConfirmationRequired:
          json['isEmailConfirmationRequired'] as bool? ?? false,
      isEmailConfirmed: json['isEmailConfirmed'] as bool? ?? false,
      isPhoneNumberConfirmationRequired:
          json['isPhoneNumberConfirmationRequired'] as bool? ?? false,
      isPhoneNumberConfirmed:
          json['isPhoneNumberConfirmed'] as bool? ?? false,
      phoneNumberOtp: json['phoneNumberOtp'] as String?,
      phoneNumberOtpRequestId:
          json['phoneNumberOtpRequestId'] as String?,
      emailOtpRequestId: json['emailOtpRequestId'] as String?,
      isDigitalIdentityVerified:
          json['isDigitalIdentityVerified'] as bool? ?? false,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      encryptedAccessToken: json['encryptedAccessToken'] as String?,
      phoneOtpExpireInSeconds:
          json['phoneOtpExpireInSeconds'] as int? ?? 0,
      emailOtpExpireInSeconds:
          json['emailOtpExpireInSeconds'] as int? ?? 0,
      userName: json['userName'] as String?,
      userFullName: json['userFullName'] as String?,
      user: json['user'],
      redirectUri: json['redirectUri'] as String?,
      transactionId: json['transactionId'],
    );
  }
}
