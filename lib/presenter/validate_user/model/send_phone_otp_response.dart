class SendPhoneOtpData {
  final int? phoneOtpExpireInSeconds;
  final bool isPhoneNumberConfirmed;
  final String? phoneNumberOtpRequestId;
  final String? transactionId;

  const SendPhoneOtpData({
    this.phoneOtpExpireInSeconds,
    required this.isPhoneNumberConfirmed,
    this.phoneNumberOtpRequestId,
    this.transactionId,
  });

  factory SendPhoneOtpData.fromJson(Map<String, dynamic> json) {
    final rawConfirmed = json['isPhoneNumberConfirmed'];
    final isConfirmed = rawConfirmed is bool
        ? rawConfirmed
        : rawConfirmed?.toString().toLowerCase() == 'true';

    final rawExpire = json['phoneOtpExpireInSeconds'];
    final expire = rawExpire is int ? rawExpire : int.tryParse('$rawExpire');

    String? readString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final parsed = value.toString().trim();
        if (parsed.isNotEmpty && parsed.toLowerCase() != 'null') {
          return parsed;
        }
      }
      return null;
    }

    return SendPhoneOtpData(
      phoneOtpExpireInSeconds: expire,
      isPhoneNumberConfirmed: isConfirmed,
      phoneNumberOtpRequestId: readString(const [
        'phoneNumberOtpRequestId',
        'phone_number_otp_request_id',
        'otpRequestId',
        'requestId',
      ]),
      transactionId: readString(const [
        'transactionId',
        'transaction_id',
        'transactionID',
        'trxId',
      ]),
    );
  }
}

class SendPhoneOtpResponse {
  final SendPhoneOtpData? data;
  final int? code;
  final String? message;
  final bool success;
  final String? phoneNumberOtpRequestId;
  final String? transactionId;

  const SendPhoneOtpResponse({
    this.data,
    this.code,
    this.message,
    required this.success,
    this.phoneNumberOtpRequestId,
    this.transactionId,
  });

  factory SendPhoneOtpResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    final hasExplicitSuccess = rawSuccess != null;
    final successFlag = rawSuccess is bool
        ? rawSuccess
        : rawSuccess?.toString().toLowerCase() == 'true';

    final rawCode = json['code'] ?? json['error_code'];
    final code = rawCode is int ? rawCode : int.tryParse('$rawCode');

    final data = json['data'] is Map<String, dynamic>
        ? SendPhoneOtpData.fromJson(json['data'] as Map<String, dynamic>)
        : null;

    String? readString(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final parsed = value.toString().trim();
        if (parsed.isNotEmpty && parsed.toLowerCase() != 'null') {
          return parsed;
        }
      }
      return null;
    }

    final rootPhoneOtpId = readString(json, const [
      'phoneNumberOtpRequestId',
      'phone_number_otp_request_id',
      'otpRequestId',
      'requestId',
    ]);
    final rootTransactionId = readString(json, const [
      'transactionId',
      'transaction_id',
      'transactionID',
      'trxId',
    ]);

    final phoneNumberOtpRequestId =
        rootPhoneOtpId ?? data?.phoneNumberOtpRequestId;
    final transactionId = rootTransactionId ?? data?.transactionId;

    // Local APIs use `success`; Vlens uses data + null error_code.
    final success = hasExplicitSuccess
        ? successFlag
        : (json['error_code'] == null &&
            (phoneNumberOtpRequestId != null || data != null));

    return SendPhoneOtpResponse(
      data: data,
      code: code,
      message: json['message']?.toString() ?? json['error_message']?.toString(),
      success: success,
      phoneNumberOtpRequestId: phoneNumberOtpRequestId,
      transactionId: transactionId,
    );
  }
}
