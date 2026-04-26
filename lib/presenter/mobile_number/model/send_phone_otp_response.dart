class SendPhoneOtpData {
  final int? phoneOtpExpireInSeconds;
  final bool isPhoneNumberConfirmed;

  const SendPhoneOtpData({
    this.phoneOtpExpireInSeconds,
    required this.isPhoneNumberConfirmed,
  });

  factory SendPhoneOtpData.fromJson(Map<String, dynamic> json) {
    final rawConfirmed = json['isPhoneNumberConfirmed'];
    final isConfirmed = rawConfirmed is bool
        ? rawConfirmed
        : rawConfirmed?.toString().toLowerCase() == 'true';

    final rawExpire = json['phoneOtpExpireInSeconds'];
    final expire = rawExpire is int ? rawExpire : int.tryParse('$rawExpire');

    return SendPhoneOtpData(
      phoneOtpExpireInSeconds: expire,
      isPhoneNumberConfirmed: isConfirmed,
    );
  }
}

class SendPhoneOtpResponse {
  final SendPhoneOtpData? data;
  final int? code;
  final String? message;
  final bool success;

  const SendPhoneOtpResponse({
    this.data,
    this.code,
    this.message,
    required this.success,
  });

  factory SendPhoneOtpResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    final success = rawSuccess is bool
        ? rawSuccess
        : rawSuccess?.toString().toLowerCase() == 'true';

    final rawCode = json['code'];
    final code = rawCode is int ? rawCode : int.tryParse('$rawCode');

    return SendPhoneOtpResponse(
      data: json['data'] is Map<String, dynamic>
          ? SendPhoneOtpData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      code: code,
      message: json['message']?.toString(),
      success: success,
    );
  }
}
