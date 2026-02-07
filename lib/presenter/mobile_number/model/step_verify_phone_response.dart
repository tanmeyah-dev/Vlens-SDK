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
  final String? phoneNumberOtpRequestId;
  final String? transactionId;
  final bool? isPhoneNumberConfirmed;
  final String? errorCode;
  final String? errorMessage;
  final String? errorDescriptions;
  final Map<String, dynamic>? data;

  StepVerifyPhoneResponse({
    this.phoneNumberOtpRequestId,
    this.transactionId,
    this.isPhoneNumberConfirmed,
    this.errorCode,
    this.errorMessage,
    this.errorDescriptions,
    this.data,
  });

  /// Computed property to determine if the request was successful
  /// Success is true when we have both phoneNumberOtpRequestId and transactionId
  bool get success {
    return phoneNumberOtpRequestId != null && 
           phoneNumberOtpRequestId!.isNotEmpty &&
           transactionId != null && 
           transactionId!.isNotEmpty;
  }

  factory StepVerifyPhoneResponse.fromJson(Map<String, dynamic> json) {
    // Extract from root level first
    String? phoneNumberOtpRequestId = json['phoneNumberOtpRequestId']?.toString();
    String? transactionId = json['transactionId']?.toString();
    bool? isPhoneNumberConfirmed;

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

    // Extract from data object if available
    if (json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      phoneNumberOtpRequestId = phoneNumberOtpRequestId ?? 
          dataMap['phoneNumberOtpRequestId']?.toString();
      transactionId = transactionId ?? 
          dataMap['transactionId']?.toString();
      
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
    }

    return StepVerifyPhoneResponse(
      phoneNumberOtpRequestId: phoneNumberOtpRequestId,
      transactionId: transactionId,
      isPhoneNumberConfirmed: isPhoneNumberConfirmed,
      errorCode: json['error_code']?.toString(),
      errorMessage: json['error_message']?.toString(),
      errorDescriptions: json['error_descriptions']?.toString(),
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumberOtpRequestId': phoneNumberOtpRequestId,
      'transactionId': transactionId,
      'isPhoneNumberConfirmed': isPhoneNumberConfirmed,
      'error_code': errorCode,
      'error_message': errorMessage,
      'error_descriptions': errorDescriptions,
      'data': data,
    };
  }
}
