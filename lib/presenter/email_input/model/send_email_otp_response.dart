class SendEmailOtpData {
  final int? emailOtpExpireInSeconds;
  final bool emailConfirmed;
  final String? emailOtpRequestId;
  final String? transactionId;

  const SendEmailOtpData({
    this.emailOtpExpireInSeconds,
    required this.emailConfirmed,
    this.emailOtpRequestId,
    this.transactionId,
  });

  factory SendEmailOtpData.fromJson(Map<String, dynamic> json) {
    final rawConfirmed = json['emailConfirmed'];
    final confirmed = rawConfirmed is bool
        ? rawConfirmed
        : rawConfirmed?.toString().toLowerCase() == 'true';

    final rawExpire = json['emailOtpExpireInSeconds'];
    final expire = rawExpire is int ? rawExpire : int.tryParse('$rawExpire');

    return SendEmailOtpData(
      emailOtpExpireInSeconds: expire,
      emailConfirmed: confirmed,
      emailOtpRequestId: json['emailOtpRequestId']?.toString(),
      transactionId: json['transactionId']?.toString(),
    );
  }
}

class SendEmailOtpResponse {
  final SendEmailOtpData? data;
  final int? code;
  final String? message;
  final bool success;

  const SendEmailOtpResponse({
    this.data,
    this.code,
    this.message,
    required this.success,
  });

  factory SendEmailOtpResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    final success = rawSuccess is bool
        ? rawSuccess
        : rawSuccess?.toString().toLowerCase() == 'true';

    final rawCode = json['code'];
    final code = rawCode is int ? rawCode : int.tryParse('$rawCode');

    return SendEmailOtpResponse(
      data: json['data'] is Map<String, dynamic>
          ? SendEmailOtpData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      code: code,
      message: json['message']?.toString(),
      success: success,
    );
  }
}
