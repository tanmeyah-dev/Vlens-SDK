/// Model for StepVerifyEmail API response
/// Response structure may vary, but typically includes:
/// {
///   "emailOtpRequestId": "...",
///   "transactionId": "...",
///   "isEmailConfirmed": true,
///   // OR nested in data object:
///   "data": {
///     "emailOtpRequestId": "...",
///     "transactionId": "...",
///     "isEmailConfirmed": true
///   }
/// }
class StepVerifyEmailResponse {
  final int? code;
  final String? message;
  final bool? apiSuccess;
  final String? emailOtpRequestId;
  final String? transactionId;
  final bool? isEmailConfirmed;
  final String? errorCode;
  final String? errorMessage;
  final String? errorDescriptions;
  final Map<String, dynamic>? data;

  StepVerifyEmailResponse({
    this.code,
    this.message,
    this.apiSuccess,
    this.emailOtpRequestId,
    this.transactionId,
    this.isEmailConfirmed,
    this.errorCode,
    this.errorMessage,
    this.errorDescriptions,
    this.data,
  });

  /// Computed property to determine if the request was successful
  /// Supports both old ID-based contract and new explicit success flag contract.
  bool get success {
    if (apiSuccess != null) {
      return apiSuccess == true;
    }
    return emailOtpRequestId != null && 
           emailOtpRequestId!.isNotEmpty &&
           transactionId != null && 
           transactionId!.isNotEmpty;
  }

  factory StepVerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    // Extract from root level first
    String? emailOtpRequestId = json['emailOtpRequestId']?.toString();
    String? transactionId = json['transactionId']?.toString();
    bool? isEmailConfirmed;

    // Handle isEmailConfirmed - can be bool, string, or int
    if (json['isEmailConfirmed'] != null) {
      final value = json['isEmailConfirmed'];
      if (value is bool) {
        isEmailConfirmed = value;
      } else if (value is String) {
        isEmailConfirmed = value.toLowerCase() == 'true' || value == '1';
      } else if (value is int) {
        isEmailConfirmed = value == 1;
      }
    }

    // Extract from data object if available
    if (json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      emailOtpRequestId = emailOtpRequestId ?? 
          dataMap['emailOtpRequestId']?.toString();
      transactionId = transactionId ?? 
          dataMap['transactionId']?.toString();
      
      // Handle isEmailConfirmed from data object
      if (isEmailConfirmed == null &&
          (dataMap['isEmailConfirmed'] != null ||
              dataMap['emailConfirmed'] != null)) {
        final value = dataMap['isEmailConfirmed'] ?? dataMap['emailConfirmed'];
        if (value is bool) {
          isEmailConfirmed = value;
        } else if (value is String) {
          isEmailConfirmed = value.toLowerCase() == 'true' || value == '1';
        } else if (value is int) {
          isEmailConfirmed = value == 1;
        }
      }
    }

    return StepVerifyEmailResponse(
      code: json['code'] is int ? json['code'] as int : int.tryParse('${json['code']}'),
      message: json['message']?.toString(),
      apiSuccess: json['success'] is bool
          ? json['success'] as bool
          : (json['success']?.toString().toLowerCase() == 'true'),
      emailOtpRequestId: emailOtpRequestId,
      transactionId: transactionId,
      isEmailConfirmed: isEmailConfirmed,
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
      'emailOtpRequestId': emailOtpRequestId,
      'transactionId': transactionId,
      'isEmailConfirmed': isEmailConfirmed,
      'error_code': errorCode,
      'error_message': errorMessage,
      'error_descriptions': errorDescriptions,
      'data': data,
    };
  }
}
