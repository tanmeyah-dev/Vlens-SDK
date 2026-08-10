/// Response for POST .../oauth/verify-token (Vlens StepVerifyOAuthToken).
class VerifyOAuthTokenData {
  final String? oAuthTokenVerificationRequestId;
  final bool isVerified;
  final String? validationResult;
  final String? email;

  const VerifyOAuthTokenData({
    this.oAuthTokenVerificationRequestId,
    required this.isVerified,
    this.validationResult,
    this.email,
  });

  factory VerifyOAuthTokenData.fromJson(Map<String, dynamic> json) {
    final rawVerified = json['isVerified'];
    final verified = rawVerified is bool
        ? rawVerified
        : rawVerified?.toString().toLowerCase() == 'true';

    return VerifyOAuthTokenData(
      oAuthTokenVerificationRequestId:
          json['oAuthTokenVerificationRequestId']?.toString(),
      isVerified: verified,
      validationResult: json['validationResult']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class VerifyOAuthTokenResponse {
  final VerifyOAuthTokenData? data;
  final int? code;
  final String? message;
  final bool success;
  final dynamic errorCode;

  const VerifyOAuthTokenResponse({
    this.data,
    this.code,
    this.message,
    required this.success,
    this.errorCode,
  });

  factory VerifyOAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    final hasErrorCode = json['error_code'] != null || json['errorCode'] != null;
    final success = rawSuccess is bool
        ? rawSuccess
        : rawSuccess == null
            ? !hasErrorCode && json['data'] != null
            : rawSuccess.toString().toLowerCase() == 'true';

    final rawCode = json['code'] ?? json['error_code'] ?? json['errorCode'];
    final code = rawCode is int ? rawCode : int.tryParse('$rawCode');

    Map<String, dynamic>? dataMap;
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = rawData.map((k, v) => MapEntry(k.toString(), v));
    }

    return VerifyOAuthTokenResponse(
      data: dataMap == null ? null : VerifyOAuthTokenData.fromJson(dataMap),
      code: code,
      message: json['error_message']?.toString() ??
          json['errorMessage']?.toString() ??
          json['message']?.toString() ??
          json['validationResult']?.toString() ??
          dataMap?['validationResult']?.toString(),
      success: success && !hasErrorCode,
      errorCode: json['error_code'] ?? json['errorCode'],
    );
  }
}
