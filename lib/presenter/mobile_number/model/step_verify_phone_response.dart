/// Model for StepVerifyPhone API response
/// Response structure may vary, but typically includes:
/// {
///   "phoneNumberOtpRequestId": "...",
///   "transactionId": "...",
///   "isPhoneNumberConfirmed": true,
///   // OR nested in data object:
///   "data": {
///     "phoneNumberOtpRequestId": "...",
///     "transactionId": "...",
///     "isPhoneNumberConfirmed": true
///   }
/// }
class StepVerifyPhoneResponse {
  final int? code;
  final String? message;
  final bool? apiSuccess;
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final int? phoneOtpExpireInSeconds;
  final bool? isPhoneNumberConfirmed;
  final String? errorCode;
  final String? errorMessage;
  final String? errorDescriptions;
  final Map<String, dynamic>? data;

  StepVerifyPhoneResponse({
    this.code,
    this.message,
    this.apiSuccess,
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.phoneOtpExpireInSeconds,
    this.isPhoneNumberConfirmed,
    this.errorCode,
    this.errorMessage,
    this.errorDescriptions,
    this.data,
  });

  /// Computed property to determine if the request was successful
  /// Supports both legacy contract and new contract with explicit success flag.
  bool get success {
    if (apiSuccess != null) {
      return apiSuccess == true;
    }
    return phoneNumberOtpRequestId != null && 
           phoneNumberOtpRequestId!.isNotEmpty &&
           transactionId != null && 
           transactionId!.isNotEmpty;
  }

  factory StepVerifyPhoneResponse.fromJson(Map<String, dynamic> json) {
    String? readString(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null) {
          final parsed = value.toString().trim();
          if (parsed.isNotEmpty && parsed.toLowerCase() != 'null') {
            return parsed;
          }
        }
      }
      return null;
    }

    // Extract from root level first (supports camelCase + snake_case + common variants)
    String? phoneNumberOtpRequestId = readString(json, const [
      'phoneNumberOtpRequestId',
      'phone_number_otp_request_id',
      'otpRequestId',
      'requestId',
    ]);
    String? transactionId = readString(json, const [
      'transactionId',
      'transaction_id',
      'transactionID',
      'trxId',
    ]);
    bool? isPhoneNumberConfirmed;
    int? phoneOtpExpireInSeconds;

    // Handle isPhoneNumberConfirmed - can be bool, string, or int
    if (json['isPhoneNumberConfirmed'] != null) {
      final value = json['isPhoneNumberConfirmed'];
      if (value is bool) {
        isPhoneNumberConfirmed = value;
      } else if (value is String) {
        isPhoneNumberConfirmed = value.toLowerCase() == 'true' || value == '1';
      } else if (value is int) {
        isPhoneNumberConfirmed = value == 1;
      }
    }

    // Extract from common nested objects if available
    final nestedCandidates = <Map<String, dynamic>>[];
    if (json['data'] is Map<String, dynamic>) {
      nestedCandidates.add(json['data'] as Map<String, dynamic>);
    }
    if (json['result'] is Map<String, dynamic>) {
      nestedCandidates.add(json['result'] as Map<String, dynamic>);
    }
    if (json['payload'] is Map<String, dynamic>) {
      nestedCandidates.add(json['payload'] as Map<String, dynamic>);
    }

    for (final dataMap in nestedCandidates) {
      phoneNumberOtpRequestId ??= readString(dataMap, const [
        'phoneNumberOtpRequestId',
        'phone_number_otp_request_id',
        'otpRequestId',
        'requestId',
      ]);
      transactionId ??= readString(dataMap, const [
        'transactionId',
        'transaction_id',
        'transactionID',
        'trxId',
      ]);
      
      // Handle isPhoneNumberConfirmed from data object
      if (isPhoneNumberConfirmed == null && dataMap['isPhoneNumberConfirmed'] != null) {
        final value = dataMap['isPhoneNumberConfirmed'];
        if (value is bool) {
          isPhoneNumberConfirmed = value;
        } else if (value is String) {
          isPhoneNumberConfirmed = value.toLowerCase() == 'true' || value == '1';
        } else if (value is int) {
          isPhoneNumberConfirmed = value == 1;
        }
      }

      if (phoneOtpExpireInSeconds == null &&
          dataMap['phoneOtpExpireInSeconds'] != null) {
        final value = dataMap['phoneOtpExpireInSeconds'];
        if (value is int) {
          phoneOtpExpireInSeconds = value;
        } else {
          phoneOtpExpireInSeconds = int.tryParse(value.toString());
        }
      }
    }

    return StepVerifyPhoneResponse(
      code: json['code'] is int ? json['code'] as int : int.tryParse('${json['code']}'),
      message: json['message']?.toString(),
      apiSuccess: json['success'] is bool
          ? json['success'] as bool
          : (json['success']?.toString().toLowerCase() == 'true'),
      phoneNumberOtpRequestId: phoneNumberOtpRequestId,
      transactionId: transactionId,
      phoneOtpExpireInSeconds: phoneOtpExpireInSeconds,
      isPhoneNumberConfirmed: isPhoneNumberConfirmed,
      errorCode: json['error_code']?.toString(),
      errorMessage: json['error_message']?.toString(),
      errorDescriptions: json['error_descriptions']?.toString(),
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'success': apiSuccess,
      'phoneNumberOtpRequestId': phoneNumberOtpRequestId,
      'transactionId': transactionId,
      'phoneOtpExpireInSeconds': phoneOtpExpireInSeconds,
      'isPhoneNumberConfirmed': isPhoneNumberConfirmed,
      'error_code': errorCode,
      'error_message': errorMessage,
      'error_descriptions': errorDescriptions,
      'data': data,
    };
  }
}
